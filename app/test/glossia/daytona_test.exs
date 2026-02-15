defmodule Glossia.DaytonaTest do
  use ExUnit.Case, async: true

  alias Glossia.Daytona

  @api_opts [api_key: "test-key", req_options: [plug: {Req.Test, __MODULE__}]]
  @proxy_opts [
    api_key: "test-key",
    proxy_url: "http://proxy.test",
    req_options: [plug: {Req.Test, __MODULE__}]
  ]

  describe "create_sandbox/2" do
    test "returns sandbox on success" do
      Req.Test.stub(__MODULE__, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = JSON.decode!(body)
        assert decoded["language"] == "python"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "sb-123", "state" => "running"}))
      end)

      assert {:ok, %{"id" => "sb-123"}} =
               Daytona.create_sandbox(%{language: "python"}, @api_opts)
    end

    test "returns http_error for non-2xx status" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(422, JSON.encode!(%{"error" => "invalid"}))
      end)

      assert {:error, {:http_error, 422, _body}} =
               Daytona.create_sandbox(%{language: "python"}, @api_opts)
    end

    test "returns not_configured when API key is missing" do
      assert {:error, :not_configured} = Daytona.create_sandbox(%{language: "python"})
    end
  end

  describe "get_sandbox/2" do
    test "returns sandbox on success" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "sb-123", "state" => "running"}))
      end)

      assert {:ok, %{"id" => "sb-123", "state" => "running"}} =
               Daytona.get_sandbox("sb-123", @api_opts)
    end

    test "returns http_error for 404" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(404, JSON.encode!(%{"error" => "not found"}))
      end)

      assert {:error, {:http_error, 404, _body}} = Daytona.get_sandbox("missing", @api_opts)
    end

    test "returns not_configured when API key is missing" do
      assert {:error, :not_configured} = Daytona.get_sandbox("sb-123")
    end
  end

  describe "list_sandboxes/1" do
    test "returns list on success" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          JSON.encode!([%{"id" => "sb-1"}, %{"id" => "sb-2"}])
        )
      end)

      assert {:ok, [%{"id" => "sb-1"}, %{"id" => "sb-2"}]} =
               Daytona.list_sandboxes(@api_opts)
    end

    test "returns not_configured when API key is missing" do
      assert {:error, :not_configured} = Daytona.list_sandboxes()
    end
  end

  describe "delete_sandbox/2" do
    test "returns :ok on success" do
      Req.Test.stub(__MODULE__, fn conn ->
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert :ok = Daytona.delete_sandbox("sb-123", @api_opts)
    end

    test "returns http_error for non-2xx status" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(404, JSON.encode!(%{"error" => "not found"}))
      end)

      assert {:error, {:http_error, 404, _body}} = Daytona.delete_sandbox("sb-123", @api_opts)
    end

    test "returns not_configured when API key is missing" do
      assert {:error, :not_configured} = Daytona.delete_sandbox("sb-123")
    end
  end

  describe "start_sandbox/2" do
    test "returns :ok on success" do
      Req.Test.stub(__MODULE__, fn conn ->
        Plug.Conn.send_resp(conn, 200, "")
      end)

      assert :ok = Daytona.start_sandbox("sb-123", @api_opts)
    end

    test "returns not_configured when API key is missing" do
      assert {:error, :not_configured} = Daytona.start_sandbox("sb-123")
    end
  end

  describe "stop_sandbox/2" do
    test "returns :ok on success" do
      Req.Test.stub(__MODULE__, fn conn ->
        Plug.Conn.send_resp(conn, 200, "")
      end)

      assert :ok = Daytona.stop_sandbox("sb-123", @api_opts)
    end

    test "returns not_configured when API key is missing" do
      assert {:error, :not_configured} = Daytona.stop_sandbox("sb-123")
    end
  end

  describe "execute/3" do
    test "returns command output on success" do
      Req.Test.stub(__MODULE__, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = JSON.decode!(body)
        assert decoded["command"] == "echo hello"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          JSON.encode!(%{"exitCode" => 0, "stdout" => "hello\n", "stderr" => ""})
        )
      end)

      assert {:ok, %{"exitCode" => 0, "stdout" => "hello\n"}} =
               Daytona.execute("sb-123", %{command: "echo hello"}, @proxy_opts)
    end

    test "returns http_error for non-200 status" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(500, JSON.encode!(%{"error" => "sandbox not running"}))
      end)

      assert {:error, {:http_error, 500, _body}} =
               Daytona.execute("sb-123", %{command: "echo hello"}, @proxy_opts)
    end

    test "returns not_configured when API key is missing" do
      assert {:error, :not_configured} = Daytona.execute("sb-123", %{command: "echo hello"})
    end
  end

  describe "upload_file/4" do
    test "returns :ok on success" do
      Req.Test.stub(__MODULE__, fn conn ->
        Plug.Conn.send_resp(conn, 200, "")
      end)

      assert :ok = Daytona.upload_file("sb-123", "/tmp/test.txt", "content", @proxy_opts)
    end

    test "returns not_configured when API key is missing" do
      assert {:error, :not_configured} =
               Daytona.upload_file("sb-123", "/tmp/test.txt", "content")
    end
  end

  describe "download_file/3" do
    test "returns file content on success" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/octet-stream")
        |> Plug.Conn.send_resp(200, "file content here")
      end)

      assert {:ok, "file content here"} =
               Daytona.download_file("sb-123", "/tmp/test.txt", @proxy_opts)
    end

    test "returns http_error for 404" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(404, JSON.encode!(%{"error" => "file not found"}))
      end)

      assert {:error, {:http_error, 404, _body}} =
               Daytona.download_file("sb-123", "/tmp/missing.txt", @proxy_opts)
    end

    test "returns not_configured when API key is missing" do
      assert {:error, :not_configured} = Daytona.download_file("sb-123", "/tmp/test.txt")
    end
  end
end
