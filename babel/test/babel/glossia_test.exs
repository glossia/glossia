defmodule Babel.GlossiaTest do
  use ExUnit.Case, async: true

  alias Babel.Glossia

  @tag :tmp_dir
  test "sends the projected token to Glossia's database endpoint", %{tmp_dir: tmp_dir} do
    token_path = Path.join(tmp_dir, "token")
    File.write!(token_path, "projected-token\n")

    request = fn request ->
      assert request.method == :post

      assert URI.to_string(request.url) ==
               "http://glossia.glossia.svc.cluster.local/api/internal/babel/db/query"

      assert request.options[:auth] == {:bearer, "projected-token"}
      assert request.options[:json] == %{"limit" => 10, "query" => "SELECT 1"}

      {:ok,
       %Req.Response{
         status: 200,
         body: %{"columns" => ["one"], "rows" => [%{"one" => 1}], "truncated" => false}
       }}
    end

    assert {:ok, %{"rows" => [%{"one" => 1}]}} =
             Glossia.query("SELECT 1",
               base_url: "http://glossia.glossia.svc.cluster.local",
               token_path: token_path,
               request: request,
               limit: 10
             )
  end

  test "does not consider a missing workload token configured" do
    refute Glossia.configured?(
             base_url: "http://glossia.glossia.svc.cluster.local",
             token_path: "/missing/token"
           )
  end

  test "returns the internal error without leaking the token" do
    request = fn _request ->
      {:ok, %Req.Response{status: 401, body: %{"error" => "invalid_workload_identity"}}}
    end

    assert {:error, "invalid_workload_identity"} =
             Glossia.query("SELECT 1",
               base_url: "http://glossia.glossia.svc.cluster.local",
               token: "secret-token",
               request: request
             )
  end
end
