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
               "https://glossia-babel.glossia.svc.cluster.local/api/internal/babel/db/query"

      assert request.options[:auth] == {:bearer, "projected-token"}
      assert request.options[:connect_options] == [hostname: "babel-internal.glossia.ai"]
      assert request.options[:json] == %{"limit" => 10, "query" => "SELECT 1"}

      {:ok,
       %Req.Response{
         status: 200,
         body: %{"columns" => ["one"], "rows" => [%{"one" => 1}], "truncated" => false}
       }}
    end

    assert {:ok, %{"rows" => [%{"one" => 1}]}} =
             Glossia.query("SELECT 1",
               base_url: "https://glossia-babel.glossia.svc.cluster.local",
               token_path: token_path,
               tls_server_name: "babel-internal.glossia.ai",
               request: request,
               limit: 10
             )
  end

  test "does not consider a missing workload token configured" do
    refute Glossia.configured?(
             base_url: "https://glossia-babel.glossia.svc.cluster.local",
             tls_server_name: "babel-internal.glossia.ai",
             token_path: "/missing/token"
           )
  end

  test "sends ClickHouse queries to the private analytics endpoint" do
    request = fn request ->
      assert URI.to_string(request.url) ==
               "https://glossia-babel.glossia.svc.cluster.local/api/internal/babel/clickhouse/query"

      assert request.options[:json] == %{
               "query" => "SELECT count() AS events FROM analytics_events"
             }

      {:ok, %Req.Response{status: 200, body: %{"rows" => [%{"events" => 1}]}}}
    end

    assert {:ok, %{"rows" => [%{"events" => 1}]}} =
             Glossia.clickhouse_query("SELECT count() AS events FROM analytics_events",
               base_url: "https://glossia-babel.glossia.svc.cluster.local",
               token: "projected-token",
               tls_server_name: "babel-internal.glossia.ai",
               request: request
             )
  end

  test "returns the internal error without leaking the token" do
    request = fn _request ->
      {:ok, %Req.Response{status: 401, body: %{"error" => "invalid_workload_identity"}}}
    end

    assert {:error, "invalid_workload_identity"} =
             Glossia.query("SELECT 1",
               base_url: "https://glossia-babel.glossia.svc.cluster.local",
               token: "secret-token",
               tls_server_name: "babel-internal.glossia.ai",
               request: request
             )
  end

  test "refuses a cleartext Glossia URL" do
    assert {:error, "The Glossia internal API URL must use HTTPS."} =
             Glossia.query("SELECT 1",
               base_url: "http://glossia-babel.glossia.svc.cluster.local",
               token: "projected-token",
               tls_server_name: "babel-internal.glossia.ai"
             )
  end
end
