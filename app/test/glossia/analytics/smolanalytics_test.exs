defmodule Glossia.Analytics.SmolanalyticsTest do
  use ExUnit.Case, async: false

  alias Glossia.Analytics.Smolanalytics
  alias Glossia.Events.Event

  setup {Req.Test, :verify_on_exit!}

  setup do
    previous = Application.fetch_env!(:glossia, Smolanalytics)

    Application.put_env(:glossia, Smolanalytics,
      enabled: true,
      url: "http://smolanalytics.test",
      write_key: "write-secret",
      environment: "test",
      request_options: [plug: {Req.Test, Smolanalytics}]
    )

    on_exit(fn -> Application.put_env(:glossia, Smolanalytics, previous) end)
  end

  test "builds an analytics event without forwarding descriptive or personal fields" do
    event =
      event(
        resource_type: "project",
        resource_id: 42,
        summary: "user@example.com created a private project",
        via: :dashboard
      )

    analytics_event = Smolanalytics.build_event(event)

    assert analytics_event["name"] == "project.created"
    assert analytics_event["distinct_id"] == "user:user-456"
    assert analytics_event["timestamp"] == "2026-07-24T10:30:00Z"

    assert analytics_event["properties"] == %{
             "account_id" => "account-123",
             "actor_type" => "user",
             "environment" => "test",
             "resource_id" => "42",
             "resource_type" => "project",
             "user_id" => "user-456",
             "via" => "dashboard"
           }

    refute Map.has_key?(analytics_event["properties"], "summary")
  end

  test "delivers an event with bearer authentication" do
    Req.Test.expect(Smolanalytics, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/v1/events"
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer write-secret"]

      body = conn |> Req.Test.raw_body() |> Jason.decode!()
      assert body["name"] == "project.created"
      assert body["distinct_id"] == "user:user-456"

      Plug.Conn.send_resp(conn, 202, ~s({"accepted":1}))
    end)

    job = %Oban.Job{args: %{"event" => Smolanalytics.build_event(event())}}

    assert :ok = Smolanalytics.perform(job)
  end

  test "handles a domain event through the analytics background queue" do
    Req.Test.expect(Smolanalytics, fn conn ->
      body = conn |> Req.Test.raw_body() |> Jason.decode!()
      assert body["name"] == "project.created"
      assert body["properties"]["account_id"] == "account-123"

      Plug.Conn.send_resp(conn, 202, ~s({"accepted":1}))
    end)

    assert :ok = Smolanalytics.handle_event(event())
  end

  test "returns an error so Oban retries failed delivery" do
    Req.Test.expect(Smolanalytics, fn conn ->
      Plug.Conn.send_resp(conn, 503, ~s({"error":"unavailable"}))
    end)

    job = %Oban.Job{args: %{"event" => Smolanalytics.build_event(event())}}

    assert {:error, message} = Smolanalytics.perform(job)
    assert message =~ "HTTP 503"
  end

  defp event(opts \\ []) do
    %Event{
      name: "project.created",
      account: %{id: "account-123"},
      user: %{id: "user-456"},
      opts: opts,
      occurred_at: ~U[2026-07-24 10:30:00Z]
    }
  end
end
