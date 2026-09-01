defmodule Glossia.Translations.TogetherTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Together

  setup {Req.Test, :verify_on_exit!}

  test "disables hybrid reasoning when calling a Bifrost gateway" do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/v1/chat/completions"
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test-key"]

      assert {:ok,
              %{
                "model" => "Qwen/Qwen3.5-9B",
                "stream" => false,
                "max_tokens" => 8192,
                "reasoning" => %{"enabled" => false}
              }} = conn |> Req.Test.raw_body() |> IO.iodata_to_binary() |> JSON.decode()

      Req.Test.json(conn, %{
        "choices" => [%{"finish_reason" => "stop", "message" => %{"content" => "Hola"}}]
      })
    end)

    assert {:ok, "Hola"} =
             Together.complete(
               "Qwen/Qwen3.5-9B",
               "test-key",
               "http://bifrost.test/v1",
               [%{role: "user", content: "Translate hello."}],
               max_tokens: 8192,
               plug: {Req.Test, __MODULE__}
             )
  end

  test "preserves an output-limit failure" do
    Req.Test.expect(__MODULE__, fn conn ->
      Req.Test.json(conn, %{
        "choices" => [%{"finish_reason" => "length", "message" => %{"content" => "Hola"}}]
      })
    end)

    assert {:error, {:output_limit_reached, 5}} =
             Together.complete(
               "Qwen/Qwen3.5-9B",
               "test-key",
               "http://bifrost.test/v1",
               [%{role: "user", content: "Translate hello."}],
               plug: {Req.Test, __MODULE__}
             )
  end
end
