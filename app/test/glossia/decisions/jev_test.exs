defmodule Glossia.Decisions.JevTest do
  use ExUnit.Case, async: true

  alias Glossia.Decisions.Jev

  setup {Req.Test, :verify_on_exit!}

  test "uses the native endpoint, bearer key, model name, and typed questions" do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.request_path == "/v1/systemone"
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer secret"]
      body = conn |> Req.Test.raw_body() |> IO.iodata_to_binary() |> JSON.decode!()
      assert body["model"] == "jev-latest"
      assert body["state"] == %{"source" => "Hello", "translation" => "Hola"}
      assert body["questions"]["meaning"]["type"] == "score"

      Req.Test.json(conn, %{
        model: "jev-1.13.0",
        answers: %{meaning: %{type: "score", score: 8.0, confidence: 0.9}}
      })
    end)

    assert {:ok, %{"model" => "jev-1.13.0"}} =
             Jev.evaluate(
               "typesafe/jev-latest",
               "secret",
               nil,
               %{source: "Hello", translation: "Hola"},
               %{
                 meaning: %{
                   type: "score",
                   instructions: "Preserves meaning?",
                   criteria: ["No", "Yes"]
                 }
               },
               plug: {Req.Test, __MODULE__}
             )
  end

  test "uses custom endpoints and never returns provider response bodies" do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.request_path == "/custom/v1/systemone"
      conn |> Plug.Conn.put_status(401) |> Req.Test.json(%{error: "secret source and key"})
    end)

    assert {:error, {:decision_request_failed, 401}} =
             Jev.evaluate(
               "typesafe/jev-latest",
               "secret",
               "https://gateway.example/custom/v1",
               %{},
               %{},
               plug: {Req.Test, __MODULE__}
             )
  end

  test "retries overload and rate limits without repeating generation" do
    for status <- [429, 529, 503] do
      Req.Test.expect(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("retry-after", "3600")
        |> Plug.Conn.put_status(status)
        |> Req.Test.json(%{error: "temporary"})
      end)

      Req.Test.expect(__MODULE__, &Req.Test.json(&1, %{answers: %{}}))

      assert {:ok, _} =
               Jev.evaluate("typesafe/jev-latest", "secret", nil, %{}, %{},
                 plug: {Req.Test, __MODULE__},
                 retry_delay: 0
               )
    end
  end

  test "transient failures have a bounded provider retry budget" do
    Req.Test.expect(__MODULE__, 4, fn conn ->
      conn |> Plug.Conn.put_status(529) |> Req.Test.json(%{error: "temporary"})
    end)

    assert {:error, {:decision_request_failed, 529}} =
             Jev.evaluate("typesafe/jev-latest", "secret", nil, %{}, %{},
               plug: {Req.Test, __MODULE__},
               retry_delay: 0
             )
  end

  test "rejects malformed successful responses" do
    Req.Test.expect(__MODULE__, &Req.Test.json(&1, %{answers: nil}))

    assert {:error, :invalid_decision_response} =
             Jev.evaluate("typesafe/jev-latest", "secret", nil, %{}, %{},
               plug: {Req.Test, __MODULE__}
             )
  end
end
