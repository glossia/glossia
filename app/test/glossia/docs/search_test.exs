defmodule Glossia.Docs.SearchTest do
  use ExUnit.Case, async: false

  alias Glossia.Docs.Search

  setup {Req.Test, :verify_on_exit!}

  setup do
    previous = Application.fetch_env!(:glossia, Search)

    Application.put_env(:glossia, Search,
      enabled: true,
      url: "http://typesense.test",
      api_key: "typesense-secret",
      request_options: [plug: {Req.Test, Search}]
    )

    on_exit(fn -> Application.put_env(:glossia, Search, previous) end)
  end

  test "indexes documentation pages with auto-generated embeddings" do
    Req.Test.expect(Search, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/collections"
      assert Plug.Conn.get_req_header(conn, "x-typesense-api-key") == ["typesense-secret"]

      collection = conn |> Req.Test.raw_body() |> JSON.decode!()
      embedding = Enum.find(collection["fields"], &(&1["name"] == "embedding"))

      assert embedding["embed"]["from"] == ["title", "summary", "headings", "content"]
      assert embedding["embed"]["model_config"]["model_name"] == "ts/all-MiniLM-L12-v2"

      json_response(conn, 201, %{})
    end)

    Req.Test.expect(Search, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/collections/glossia_docs/documents/import"
      assert conn.query_string == "action=upsert"

      documents =
        conn
        |> Req.Test.raw_body()
        |> String.split("\n", trim: true)
        |> Enum.map(&JSON.decode!/1)

      assert Enum.all?(documents, &(&1["locale"] in Glossia.I18n.locales()))
      assert Enum.all?(documents, &(&1["version"] != ""))
      assert Enum.all?(documents, &String.match?(&1["url"], ~r{^/(?:[^/]+/)?docs/}))
      refute Enum.any?(documents, &String.contains?(&1["url"], "issues"))

      json_response(conn, 200, %{})
    end)

    Req.Test.expect(Search, fn conn ->
      assert conn.method == "DELETE"
      assert conn.request_path == "/collections/glossia_docs/documents"
      assert conn.query_string =~ "filter_by=version%3A%21%3D"

      json_response(conn, 200, %{"num_deleted" => 0})
    end)

    assert :ok = Search.ensure_indexed()
  end

  test "uses hybrid fuzzy and semantic search for the requested locale" do
    Req.Test.expect(Search, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/multi_search"
      assert Plug.Conn.get_req_header(conn, "x-typesense-api-key") == ["typesense-secret"]

      search = conn |> Req.Test.raw_body() |> JSON.decode!() |> get_in(["searches", Access.at(0)])

      assert search["collection"] == "glossia_docs"
      assert search["filter_by"] == "locale:=es"
      assert search["num_typos"] == 2
      assert search["query_by"] == "title,summary,headings,content,embedding"
      assert search["vector_query"] =~ "embedding:([]"

      json_response(conn, 200, %{
        "results" => [
          %{
            "hits" => [
              %{
                "document" => %{
                  "title" => "Add a new language",
                  "summary" => "Fallback summary",
                  "url" => "/es/docs/how-to/add-a-new-language"
                },
                "highlights" => [
                  %{"field" => "content", "snippet" => "Add a <mark>language</mark>."}
                ]
              }
            ]
          }
        ]
      })
    end)

    assert {:ok, [result]} = Search.search("añadir idioma", "es")
    assert result.title == "Add a new language"
    assert result.summary == "Add a language."
    assert result.url == "/es/docs/how-to/add-a-new-language"
  end

  defp json_response(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, JSON.encode!(body))
  end
end
