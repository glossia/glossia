defmodule BabelWeb.Errors.EnvelopeControllerTest do
  use BabelWeb.ConnCase, async: false

  alias Babel.Errors
  alias Babel.Errors.Event
  alias Babel.Errors.Issue
  alias Babel.Organizations.Organization
  alias Babel.Repo

  setup %{conn: conn} do
    n = System.unique_integer([:positive])

    {:ok, org} =
      %Organization{}
      |> Organization.changeset(%{
        "name" => "Acme #{n}",
        "website_url" => "https://acme-#{n}.example"
      })
      |> Repo.insert()

    {:ok, key} = Errors.create_key(org.id, %{"name" => "default"})

    conn = put_req_header(conn, "content-type", "application/x-sentry-envelope")

    %{conn: conn, org: org, key: key}
  end

  describe "POST /api/:project_id/envelope/" do
    test "ingests a valid envelope and rolls up into an issue", %{
      conn: conn,
      org: org,
      key: key
    } do
      event_id = random_event_id()

      body = envelope(event_id)

      conn =
        conn
        |> put_req_header(
          "x-sentry-auth",
          "Sentry sentry_version=7, sentry_key=#{key.public_key}"
        )
        |> post("/api/#{key.dsn_project_id}/envelope/", body)

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["id"] == event_id

      # Coalescer flushes asynchronously; the event row is written
      # synchronously and the issue row is upserted inline by the
      # context module, so both should be visible immediately.
      wait_for(fn -> Repo.aggregate(Issue, :count, :id) > 0 end)

      [issue] = Repo.all(Issue)
      assert issue.organization_id == org.id
      assert issue.title =~ "RuntimeError"

      [event] = Repo.all(Event)
      assert event.issue_id == issue.id
      assert event.organization_id == org.id
    end

    test "same fingerprint upserts a single issue with two events", %{
      conn: conn,
      key: key
    } do
      body1 = envelope(random_event_id())
      body2 = envelope(random_event_id())

      conn =
        conn
        |> put_req_header(
          "x-sentry-auth",
          "Sentry sentry_version=7, sentry_key=#{key.public_key}"
        )

      assert %{status: 200} = post(conn, "/api/#{key.dsn_project_id}/envelope/", body1)
      assert %{status: 200} = post(conn, "/api/#{key.dsn_project_id}/envelope/", body2)

      wait_for(fn -> Repo.aggregate(Event, :count, :event_id) == 2 end)

      assert Repo.aggregate(Issue, :count, :id) == 1
      assert Repo.aggregate(Event, :count, :event_id) == 2
    end

    test "accepts sentry_key from query param when header is missing", %{
      conn: conn,
      key: key
    } do
      body = envelope(random_event_id())

      conn = post(conn, "/api/#{key.dsn_project_id}/envelope/?sentry_key=#{key.public_key}", body)

      assert conn.status == 200
    end

    test "rejects unknown public key with 401", %{conn: conn, key: key} do
      body = envelope(random_event_id())

      conn =
        conn
        |> put_req_header("x-sentry-auth", "Sentry sentry_version=7, sentry_key=notarealkey")
        |> post("/api/#{key.dsn_project_id}/envelope/", body)

      assert conn.status == 401
      assert Jason.decode!(conn.resp_body) == %{"detail" => "invalid_dsn"}
    end

    test "rejects mismatched project id with 401", %{conn: conn, key: key} do
      body = envelope(random_event_id())

      conn =
        conn
        |> put_req_header(
          "x-sentry-auth",
          "Sentry sentry_version=7, sentry_key=#{key.public_key}"
        )
        |> post("/api/999999/envelope/", body)

      assert conn.status == 401
      assert Jason.decode!(conn.resp_body) == %{"detail" => "invalid_dsn"}
    end

    test "responds to CORS preflight with permissive headers", %{conn: conn, key: key} do
      conn = options(conn, "/api/#{key.dsn_project_id}/envelope/")

      assert conn.status == 200
      assert ["*"] = get_resp_header(conn, "access-control-allow-origin")
      assert ["POST, OPTIONS"] = get_resp_header(conn, "access-control-allow-methods")

      [allow_headers] = get_resp_header(conn, "access-control-allow-headers")
      assert allow_headers =~ "x-sentry-auth"
      assert allow_headers =~ "sentry-trace"
    end
  end

  ## helpers

  defp envelope(event_id) do
    envelope_header = %{
      "event_id" => event_id,
      "sent_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    item_header = %{"type" => "event"}

    payload = %{
      "event_id" => event_id,
      "timestamp" => DateTime.utc_now() |> DateTime.to_unix(),
      "platform" => "elixir",
      "level" => "error",
      "exception" => %{
        "values" => [
          %{
            "type" => "RuntimeError",
            "value" => "kaboom",
            "stacktrace" => %{
              "frames" => [
                %{
                  "filename" => "lib/babel/thing.ex",
                  "function" => "Babel.Thing.blow_up/0",
                  "module" => "Babel.Thing",
                  "lineno" => 42,
                  "in_app" => true
                }
              ]
            }
          }
        ]
      }
    }

    Enum.join(
      [Jason.encode!(envelope_header), Jason.encode!(item_header), Jason.encode!(payload)],
      "\n"
    ) <> "\n"
  end

  defp random_event_id do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp wait_for(fun, timeout \\ 2_000) do
    deadline = System.monotonic_time(:millisecond) + timeout

    Stream.repeatedly(fn -> {fun.(), System.monotonic_time(:millisecond)} end)
    |> Enum.find(fn {result, now} -> result or now > deadline end)
    |> case do
      {true, _} -> :ok
      _ -> Process.sleep(50)
    end
  end
end
