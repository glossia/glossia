defmodule Glossia.Editor.PreviewDiscoveryTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Glossia.Editor.{Preview, PreviewDiscovery}
  alias Glossia.Sandbox.LocalAdapter

  defmodule AuditedAdapter do
    def execute_preview(id, command, opts) do
      send(self(), {:sandbox_command, command, opts})
      Glossia.Sandbox.LocalAdapter.execute_preview(id, command, opts)
    end
  end

  setup do
    old = Application.get_env(:glossia, Preview)
    Application.put_env(:glossia, Preview, trusted_local: true)

    on_exit(fn ->
      if old,
        do: Application.put_env(:glossia, Preview, old),
        else: Application.delete_env(:glossia, Preview)
    end)

    id = Ecto.UUID.generate()
    assert {:ok, _} = LocalAdapter.create(%{id: id})
    on_exit(fn -> LocalAdapter.delete(id) end)
    {:ok, root} = LocalAdapter.repo_path(id)

    File.write!(
      Path.join(root, "package.json"),
      ~s({"scripts":{"dev":"node server.mjs","postinstall":"touch SHOULD_NOT_EXECUTE"}})
    )

    File.write!(
      Path.join(root, "server.mjs"),
      "// /es/products renders es/products.json; bind process.env.HOST and PORT"
    )

    File.write!(Path.join(root, ".env"), "PRODUCTION_SECRET=do-not-read")
    File.write!(Path.join(root, "secrets.json"), ~s({"key":"do-not-read"}))
    File.write!(Path.join(root, "large.ts"), String.duplicate("x", 32_001))
    File.ln_s!("/etc/passwd", Path.join(root, "escape.ts"))

    record = %{
      path: "es/products.json",
      source_path: "en/products.json",
      locale: "es",
      format: "json",
      content: ~s({"title":"Original product"}),
      draft_content: nil
    }

    %{id: id, root: root, record: record}
  end

  test "model runs on trusted parent with bounded read-only source, never uploads credentials or runs scripts",
       c do
    credential = %{model: "openai/gpt-4o-mini", auth: {:api_key, "PARENT-ONLY-MODEL-KEY", nil}}

    stub(Req, :request, fn request ->
      send(self(), {:provider_request, request})

      case Process.get(:preview_model_round, 0) do
        0 ->
          Process.put(:preview_model_round, 1)
          provider_response(~s({"read":["package.json","server.mjs"]}))

        1 ->
          provider_response(
            JSON.encode!(%{
              command: "exec node server.mjs",
              path: "/es/products",
              evidence: "Original product",
              reason: "server.mjs maps locale route to products.json"
            })
          )
      end
    end)

    assert {:ok, %{"path" => "/es/products"}} =
             PreviewDiscovery.discover_with_credential(
               AuditedAdapter,
               c.id,
               c.root,
               credential,
               c.record
             )

    assert_receive {:provider_request, first}
    assert_receive {:provider_request, second}

    for request <- [first, second] do
      assert request.options[:redirect] == false
      assert request.options[:retry] == false
      assert request.options[:receive_timeout] == 60_000
      assert Req.Request.get_header(request, "authorization") == ["Bearer PARENT-ONLY-MODEL-KEY"]
    end

    data =
      second.options.context.messages
      |> List.last()
      |> Map.fetch!(:content)
      |> Enum.map_join(& &1.text)
      |> JSON.decode!()

    assert data["sources"]["server.mjs"] =~ "/es/products renders es/products.json"

    commands = drain_commands()
    assert length(commands) == 2

    for {command, opts} <- commands do
      assert String.starts_with?(command, "node -e ")
      refute command =~ "PARENT-ONLY-MODEL-KEY"
      refute inspect(opts) =~ "PARENT-ONLY-MODEL-KEY"
      refute command =~ "opencode"
      refute command =~ "codex"
    end

    refute File.exists?(Path.join(c.root, "SHOULD_NOT_EXECUTE"))
    refute File.exists?(Path.join(Path.dirname(c.root), ".glossia-harness"))
  end

  test "Codex OAuth is prepared directly on the parent without any CLI or sandbox auth" do
    claims = %{"https://api.openai.com/auth" => %{"chatgpt_account_id" => "preview-test-account"}}
    token = "test." <> Base.url_encode64(JSON.encode!(claims), padding: false) <> ".signature"

    stub(Req, :request, fn request ->
      assert request.options.model == "gpt-5"
      assert URI.to_string(request.url) =~ "/codex/responses"
      assert Req.Request.get_header(request, "authorization") == ["Bearer " <> token]
      assert Req.Request.get_header(request, "chatgpt-account-id") == ["preview-test-account"]
      assert request.options[:redirect] == false
      assert request.options[:retry] == false
      {:ok, response} = provider_response("")
      {:ok, %{response | body: %{response.body | object: %{"read" => ["package.json"]}}}}
    end)

    assert {:ok, ~s({"read":["package.json"]})} =
             PreviewDiscovery.request(
               %{model: "openai/gpt-5", auth: {:oauth, token}, source: :codex_session},
               "{}"
             )

    refute_receive {:sandbox_command, _, _}
  end

  test "Anthropic OAuth is prepared directly on the parent" do
    stub(Req, :request, fn request ->
      assert Req.Request.get_header(request, "authorization") == ["Bearer parent-oauth-token"]
      assert request.options[:redirect] == false
      provider_response(~s({"read":["package.json"]}))
    end)

    assert {:ok, _} =
             PreviewDiscovery.request(
               %{
                 model: "anthropic/claude-sonnet-4-20250514",
                 auth: {:oauth, "parent-oauth-token"},
                 source: :claude_session
               },
               "{}"
             )

    refute_receive {:sandbox_command, _, _}
  end

  test "unsupported OAuth sessions fail before any repository command", c do
    assert {:error, :preview_model_auth_unavailable} =
             PreviewDiscovery.discover_with_credential(
               AuditedAdapter,
               c.id,
               c.root,
               %{
                 model: "openai/gpt-5",
                 auth: {:oauth, "MUST-NOT-ENTER-SANDBOX"},
                 source: :unsupported_session
               },
               c.record
             )

    refute_receive {:sandbox_command, _, _}
  end

  test "source reader refuses secrets, traversal, symlinks and oversized source", c do
    assert {:ok, %{"paths" => paths}} = PreviewDiscovery.source(AuditedAdapter, c.id, c.root, [])
    assert "server.mjs" in paths
    refute "escape.ts" in paths
    refute ".env" in paths
    refute "secrets.json" in paths

    for path <- [".env", "secrets.json", "escape.ts", "../outside.ts", "/etc/passwd", "large.ts"] do
      assert {:error, :discovery_source_limit} =
               PreviewDiscovery.source(AuditedAdapter, c.id, c.root, [path])
    end
  end

  test "malicious model read requests cannot become filesystem tools", c do
    stub(Req, :request, fn _ -> provider_response(~s({"read":["../../.codex/auth.json"]})) end)

    assert {:error, :discovery_source_limit} =
             PreviewDiscovery.discover_with_credential(
               AuditedAdapter,
               c.id,
               c.root,
               %{model: "openai/gpt-4o-mini", auth: {:api_key, "parent-only", nil}},
               c.record
             )

    assert length(drain_commands()) == 1
  end

  defp provider_response(text) do
    {:ok,
     %Req.Response{
       status: 200,
       body: %ReqLLM.Response{
         id: "static-preview",
         model: "openai:gpt-4o-mini",
         context: ReqLLM.Context.new([]),
         message: ReqLLM.Context.assistant(text)
       }
     }}
  end

  defp drain_commands(acc \\ []) do
    receive do
      {:sandbox_command, command, opts} -> drain_commands([{command, opts} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end
end
