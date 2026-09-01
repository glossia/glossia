defmodule Glossia.Docs.Search do
  @moduledoc false

  alias Glossia.Docs

  @collection "glossia_docs"
  @query_by "title,summary,headings,content,embedding"
  @query_by_weights "127,100,80,5,5"

  def enabled? do
    configuration = config()

    configuration[:enabled] == true and present?(configuration[:url]) and
      present?(configuration[:api_key])
  end

  def ensure_indexed do
    if enabled?() do
      documents = documents()
      version = version(documents)

      with :ok <- create_collection(),
           :ok <- import_documents(documents, version),
           :ok <- remove_stale_documents(version) do
        :ok
      end
    else
      :ok
    end
  end

  def search(query, locale, limit \\ 8)

  def search(query, locale, limit) when is_binary(query) and is_binary(locale) do
    query = String.trim(query)

    cond do
      String.length(query) < 2 ->
        {:ok, []}

      not enabled?() ->
        {:error, :disabled}

      true ->
        search_typesense(query, locale, limit)
    end
  end

  def fallback_search(query, locale, limit \\ 8) when is_binary(query) and is_binary(locale) do
    normalized_query = query |> String.trim() |> String.downcase()

    if String.length(normalized_query) < 2 do
      []
    else
      locale
      |> Docs.search_index()
      |> Enum.map(fn page -> {local_score(page, normalized_query), page} end)
      |> Enum.filter(&(elem(&1, 0) > 0))
      |> Enum.sort_by(&elem(&1, 0), :desc)
      |> Enum.take(limit)
      |> Enum.map(fn {_score, page} -> Map.take(page, [:title, :summary, :url]) end)
    end
  end

  def documents do
    Glossia.I18n.locales()
    |> Enum.flat_map(fn locale ->
      locale
      |> Docs.all_pages()
      |> Enum.map(&document(&1, locale))
    end)
  end

  defp document(page, locale) do
    %{
      "id" => "#{locale}:#{page.id}",
      "locale" => locale,
      "title" => page.title,
      "summary" => page.summary,
      "headings" => Enum.map(page.toc, & &1.text),
      "content" => Glossia.MarketingMarkdown.strip_html(page.body),
      "url" =>
        locale
        |> Glossia.I18n.localize_path(Docs.path_for(page))
        |> String.trim_trailing("/")
    }
  end

  defp create_collection do
    case request(:post, "/collections", json: collection_schema()) do
      {:ok, %{status: status}} when status in 200..299 -> :ok
      {:ok, %{status: 409}} -> :ok
      {:ok, %{status: status, body: body}} -> {:error, {:create_collection, status, body}}
      {:error, reason} -> {:error, {:create_collection, reason}}
    end
  end

  defp import_documents(documents, version) do
    payload =
      documents
      |> Enum.map(&Map.put(&1, "version", version))
      |> Enum.map_join("\n", &JSON.encode!/1)

    case request(:post, "/collections/#{@collection}/documents/import",
           query: [action: "upsert"],
           body: payload,
           headers: [{"content-type", "text/plain"}],
           receive_timeout: :timer.minutes(5)
         ) do
      {:ok, %{status: status}} when status in 200..299 -> :ok
      {:ok, %{status: status, body: body}} -> {:error, {:import_documents, status, body}}
      {:error, reason} -> {:error, {:import_documents, reason}}
    end
  end

  defp remove_stale_documents(version) do
    case request(:delete, "/collections/#{@collection}/documents",
           query: [filter_by: "version:!=#{version}"]
         ) do
      {:ok, %{status: status}} when status in 200..299 -> :ok
      {:ok, %{status: status, body: body}} -> {:error, {:remove_stale_documents, status, body}}
      {:error, reason} -> {:error, {:remove_stale_documents, reason}}
    end
  end

  defp search_typesense(query, locale, limit) do
    search = %{
      "collection" => @collection,
      "q" => query,
      "query_by" => @query_by,
      "query_by_weights" => @query_by_weights,
      "filter_by" => "locale:=#{locale}",
      "highlight_full_fields" => "title,summary,headings,content",
      "num_typos" => 2,
      "per_page" => limit,
      "typo_tokens_threshold" => 1,
      "vector_query" => "embedding:([], k: 100, distance_threshold: 1.0, alpha: 0.2)"
    }

    case request(:post, "/multi_search", json: %{"searches" => [search]}) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok,
         body
         |> Map.get("results", [])
         |> List.first(%{})
         |> Map.get("hits", [])
         |> Enum.map(&result/1)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:search, status, body}}

      {:error, reason} ->
        {:error, {:search, reason}}
    end
  end

  defp result(%{"document" => document} = hit) do
    %{
      title: document["title"],
      summary: highlighted_content(hit) || document["summary"],
      url: document["url"]
    }
  end

  defp highlighted_content(hit) do
    hit
    |> Map.get("highlights", [])
    |> Enum.find_value(fn
      %{"field" => field, "snippet" => snippet} when field in ["summary", "content"] ->
        String.replace(snippet, ~r/<\/?mark>/, "")

      _ ->
        nil
    end)
  end

  defp collection_schema do
    %{
      "name" => @collection,
      "fields" => [
        %{"name" => "locale", "type" => "string", "facet" => true},
        %{"name" => "title", "type" => "string"},
        %{"name" => "summary", "type" => "string"},
        %{"name" => "headings", "type" => "string[]"},
        %{"name" => "content", "type" => "string"},
        %{"name" => "url", "type" => "string"},
        %{"name" => "version", "type" => "string", "facet" => true},
        %{
          "name" => "embedding",
          "type" => "float[]",
          "embed" => %{
            "from" => ["title", "summary", "headings", "content"],
            "model_config" => %{"model_name" => "ts/all-MiniLM-L12-v2"}
          }
        }
      ]
    }
  end

  defp version(documents) do
    documents
    |> JSON.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp local_score(page, query) do
    title = String.downcase(page.title)

    searchable =
      [page.summary, Enum.map_join(page.headings, " ", & &1.text), page.body_text]
      |> Enum.join(" ")
      |> String.downcase()

    cond do
      String.contains?(title, query) -> 3
      String.contains?(searchable, query) -> 2
      String.jaro_distance(title, query) >= 0.78 -> 1
      true -> 0
    end
  end

  defp request(method, path, options) do
    configuration = config()

    request =
      configuration
      |> Keyword.get(:request_options, [])
      |> Glossia.HTTP.new()

    options =
      options
      |> Keyword.put(:url, url(configuration, path, Keyword.get(options, :query, [])))
      |> Keyword.update(
        :headers,
        api_key_headers(configuration),
        &(&1 ++ api_key_headers(configuration))
      )
      |> Keyword.delete(:query)
      |> Keyword.put_new(:receive_timeout, 5_000)
      |> Keyword.put_new(:retry, false)

    apply(Req, method, [request, options])
  end

  defp url(configuration, path, query) do
    query = URI.encode_query(query)

    configuration
    |> Keyword.fetch!(:url)
    |> URI.merge(path)
    |> Map.put(:query, if(query == "", do: nil, else: query))
    |> URI.to_string()
  end

  defp api_key_headers(configuration) do
    [{"x-typesense-api-key", Keyword.fetch!(configuration, :api_key)}]
  end

  defp config, do: Application.fetch_env!(:glossia, __MODULE__)

  defp present?(value), do: is_binary(value) and value != ""
end
