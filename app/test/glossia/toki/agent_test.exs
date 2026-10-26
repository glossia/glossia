defmodule Glossia.Toki.AgentTest do
  use Glossia.DataCase, async: true
  use Mimic
  use Oban.Testing, repo: Glossia.Repo

  alias Glossia.{LLMModels, Projects, TestHelpers, Toki}
  alias Glossia.Toki.{Conversation, Message, RecoveryWorker, ReplyWorker}

  setup do
    unique = System.unique_integer([:positive])
    user = TestHelpers.create_user("toki-http-#{unique}@example.test", "toki-http")
    {:ok, project} = Projects.create_project(user.account, %{handle: "app", name: "Application"})
    project = Repo.preload(project, :account)
    {:ok, detail} = Toki.create_conversation(user, project, %{"id" => Ecto.UUID.generate()})
    %{user: user, project: project, conversation: detail.conversation}
  end

  test "real provider encoding and decoding persist one response without tools or extra calls",
       context do
    {server, base_url} =
      start_provider(fn socket, _parent ->
        response = %{
          id: "resp-toki",
          object: "response",
          model: "gpt-4o-mini",
          status: "completed",
          output: [
            %{
              type: "message",
              role: "assistant",
              content: [%{type: "output_text", text: "Provider boundary response"}]
            }
          ],
          usage: %{input_tokens: 10, output_tokens: 4, total_tokens: 14}
        }

        respond(socket, 200, response)
      end)

    job = enqueue(context, base_url)
    assert :ok = ReplyWorker.perform(job)
    assert :ok = ReplyWorker.perform(job)
    assert_receive {:provider_request, ^server, headers, body}
    assert headers =~ "authorization: Bearer test-provider-key"
    assert body["model"] == "gpt-4o-mini"
    assert body["max_output_tokens"] == 2_048
    refute body["tools"]
    assert [%{"role" => "system"}, %{"role" => "user"}] = body["input"]
    refute_receive {:provider_request, ^server, _, _}

    assert {:ok, %{conversation: %{status: "completed"}, messages: [_, reply]}} =
             Toki.get_conversation(context.user, context.project, context.conversation.id)

    assert reply.content == "Provider boundary response"
  end

  test "accepted request then closed response has one HTTP attempt, unlike ReqLLM's retries",
       context do
    {server, base_url} = start_provider(fn socket, _parent -> :gen_tcp.close(socket) end)

    # The control exercises the installed library's actual retry pipeline.
    assert {:error, _} =
             ReqLLM.generate_text("openai:gpt-4o-mini", "Control",
               api_key: "test-provider-key",
               base_url: base_url
             )

    for _ <- 1..4, do: assert_receive({:provider_request, ^server, _, _})
    refute_receive {:provider_request, ^server, _, _}

    job = enqueue(context, base_url)
    assert :ok = ReplyWorker.perform(job)
    assert_receive {:provider_request, ^server, _, _}
    refute_receive {:provider_request, ^server, _, _}
    assert :ok = ReplyWorker.perform(job)
    refute_receive {:provider_request, ^server, _, _}

    assert {:ok, %{conversation: failed, messages: [%{role: "user"}]}} =
             Toki.get_conversation(context.user, context.project, context.conversation.id)

    assert failed.status == "failed"
    assert failed.error == "inference_failed"
  end

  test "HTTP throttling, server failures and redirects never cause another request", context do
    for status <- [429, 503, 307] do
      {server, base_url} =
        start_provider(fn socket, _parent ->
          respond(socket, status, %{error: %{message: "Provider failure"}}, [
            "retry-after: 0\r\n",
            "location: /v1/chat/completions\r\n"
          ])
        end)

      job = enqueue(context, base_url)
      assert :ok = ReplyWorker.perform(job)
      assert_receive {:provider_request, ^server, _, _}
      refute_receive {:provider_request, ^server, _, _}
      assert Repo.get!(Conversation, context.conversation.id).status == "failed"
    end

    assert Repo.aggregate(Message, :count) == 3
  end

  test "blocked provider times out in the worker, closes the request and never retries",
       context do
    {server, base_url} = start_blocked_provider()
    job = enqueue(context, base_url)
    parent = self()

    expect(Req, :request, fn request ->
      assert request.options[:receive_timeout] == 60_000
      assert request.options[:retry] == false
      assert request.options[:max_retries] == 0
      send(parent, {:transport_owner, self()})

      request = Req.Request.merge_options(request, receive_timeout: 50)
      Mimic.call_original(Req, :request, [request])
    end)

    assert ReplyWorker.timeout(job) == 90_000
    assert :ok = ReplyWorker.perform(job)
    assert_receive {:transport_owner, ^parent}
    assert_receive {:provider_request, ^server, _, _}
    assert_receive {:provider_disconnected, ^server, {:error, :closed}}, 1_000
    refute_receive {:provider_request, ^server, _, _}
    assert Repo.get!(Conversation, context.conversation.id).status == "failed"
    assert Repo.aggregate(Message, :count) == 1
  end

  test "terminating a worker closes blocked inference; recovery and redelivery never restart it",
       context do
    {server, base_url} = start_blocked_provider()
    job = enqueue(context, base_url)

    {worker, monitor} =
      spawn_monitor(fn ->
        receive do
          :run -> ReplyWorker.perform(job)
        end
      end)

    on_exit(fn -> Process.exit(worker, :kill) end)
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), worker)
    send(worker, :run)
    assert_receive {:provider_request, ^server, _, _}, 1_000
    assert Repo.get!(Conversation, context.conversation.id).status == "running"

    Process.exit(worker, :kill)
    assert_receive {:DOWN, ^monitor, :process, ^worker, :killed}
    assert_receive {:provider_disconnected, ^server, {:error, :closed}}, 1_000
    refute_receive {:provider_request, ^server, _, _}

    from(m in Message, where: m.id == ^job.args["message_id"])
    |> Repo.update_all(set: [updated_at: DateTime.add(DateTime.utc_now(), -121)])

    assert :ok = RecoveryWorker.perform(%Oban.Job{})
    assert Repo.get!(Conversation, context.conversation.id).error == "inference_interrupted"
    assert :ok = ReplyWorker.perform(job)
    refute_receive {:provider_request, ^server, _, _}
    assert Repo.aggregate(Message, :count) == 1
  end

  defp enqueue(context, base_url) do
    {:ok, _} =
      LLMModels.create_model(context.user.account, context.user, %{
        handle: "http-#{System.unique_integer([:positive])}",
        model: "openai/gpt-4o-mini",
        api_key: "test-provider-key",
        base_url: base_url,
        default: true
      })

    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, _} =
        Toki.send_message(context.user, context.project, context.conversation.id, %{
          "id" => Ecto.UUID.generate(),
          "content" => "Hello through HTTP"
        })
    end)

    all_enqueued(worker: ReplyWorker) |> hd()
  end

  defp start_blocked_provider do
    start_provider(fn socket, parent ->
      result = :gen_tcp.recv(socket, 0, 5_000)
      send(parent, {:provider_disconnected, self(), result})
    end)
  end

  defp start_provider(handler) do
    {:ok, listener} =
      :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}, reuseaddr: true])

    {:ok, {_, port}} = :inet.sockname(listener)
    on_exit(fn -> :gen_tcp.close(listener) end)
    parent = self()

    server =
      start_supervised!({Task, fn -> accept_requests(listener, parent, handler) end},
        id: make_ref()
      )

    base_url = URI.to_string(%URI{scheme: "http", host: "127.0.0.1", port: port, path: "/v1"})
    {server, base_url}
  end

  defp accept_requests(listener, parent, handler) do
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        {headers, body} = read_request(socket, "")
        send(parent, {:provider_request, self(), headers, JSON.decode!(body)})
        handler.(socket, parent)
        :gen_tcp.close(socket)
        accept_requests(listener, parent, handler)

      {:error, :closed} ->
        :ok
    end
  end

  defp read_request(socket, data) do
    case :binary.split(data, "\r\n\r\n") do
      [headers, body] ->
        [_, length] = Regex.run(~r/content-length: (\d+)/i, headers)
        remaining = String.to_integer(length) - byte_size(body)

        if remaining > 0 do
          {:ok, rest} = :gen_tcp.recv(socket, remaining, 2_000)
          {headers, body <> rest}
        else
          {headers, body}
        end

      [_] ->
        {:ok, rest} = :gen_tcp.recv(socket, 0, 2_000)
        read_request(socket, data <> rest)
    end
  end

  defp respond(socket, status, body, headers \\ []) do
    body = JSON.encode!(body)

    :gen_tcp.send(socket, [
      "HTTP/1.1 #{status} Test\r\n",
      "content-type: application/json\r\n",
      "content-length: #{byte_size(body)}\r\n",
      "connection: close\r\n",
      headers,
      "\r\n",
      body
    ])
  end
end
