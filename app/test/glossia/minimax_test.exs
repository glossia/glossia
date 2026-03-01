defmodule Glossia.MinimaxTest do
  use ExUnit.Case, async: true

  alias Glossia.Minimax

  @test_opts [api_key: "test-key", req_options: [plug: {Req.Test, Glossia.Minimax}]]

  describe "chat/2" do
    test "returns parsed response on success" do
      Req.Test.stub(Glossia.Minimax, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          JSON.encode!(%{
            "id" => "test-id",
            "choices" => [
              %{
                "index" => 0,
                "message" => %{"role" => "assistant", "content" => "Hello!"},
                "finish_reason" => "stop"
              }
            ],
            "usage" => %{
              "total_tokens" => 10,
              "prompt_tokens" => 5,
              "completion_tokens" => 5
            },
            "base_resp" => %{"status_code" => 0, "status_msg" => "success"}
          })
        )
      end)

      messages = [%{role: "user", content: "Hi"}]
      assert {:ok, response} = Minimax.chat(messages, @test_opts)

      assert response.content == "Hello!"
      assert response.finish_reason == "stop"
      assert response.usage["total_tokens"] == 10
    end

    test "maps rate limit error code" do
      Req.Test.stub(Glossia.Minimax, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          JSON.encode!(%{
            "base_resp" => %{"status_code" => 1002, "status_msg" => "rate limit"}
          })
        )
      end)

      messages = [%{role: "user", content: "Hi"}]
      assert {:error, :rate_limited} = Minimax.chat(messages, @test_opts)
    end

    test "maps auth failure error code" do
      Req.Test.stub(Glossia.Minimax, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          JSON.encode!(%{
            "base_resp" => %{"status_code" => 1004, "status_msg" => "auth failed"}
          })
        )
      end)

      messages = [%{role: "user", content: "Hi"}]
      assert {:error, :auth_failed} = Minimax.chat(messages, @test_opts)
    end

    test "maps insufficient balance error code" do
      Req.Test.stub(Glossia.Minimax, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          JSON.encode!(%{
            "base_resp" => %{"status_code" => 1008, "status_msg" => "insufficient balance"}
          })
        )
      end)

      messages = [%{role: "user", content: "Hi"}]
      assert {:error, :insufficient_balance} = Minimax.chat(messages, @test_opts)
    end

    test "returns http_error for non-200 status" do
      Req.Test.stub(Glossia.Minimax, fn conn ->
        Plug.Conn.send_resp(conn, 500, "Internal Server Error")
      end)

      messages = [%{role: "user", content: "Hi"}]
      assert {:error, {:http_error, 500}} = Minimax.chat(messages, @test_opts)
    end

    test "returns not_configured when API key is missing" do
      messages = [%{role: "user", content: "Hi"}]
      assert {:error, :not_configured} = Minimax.chat(messages, api_key: nil)
    end
  end

  describe "stream/2" do
    test "returns not_configured when API key is missing" do
      messages = [%{role: "user", content: "Hi"}]
      assert {:error, :not_configured} = Minimax.stream(messages, api_key: nil)
    end
  end
end
