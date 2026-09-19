defmodule Babel.GoToMarket.Search.Tavily do
  @moduledoc false

  @endpoint "https://api.tavily.com/search"

  def search(query) when is_binary(query) do
    case Application.get_env(:babel, __MODULE__, []) |> Keyword.get(:api_key) do
      api_key when is_binary(api_key) and api_key != "" -> request(query, api_key)
      _api_key -> {:error, :search_not_configured}
    end
  end

  defp request(query, api_key) do
    case Req.post(url: @endpoint, json: request_body(query, api_key), receive_timeout: 20_000) do
      {:ok, %{status: 200, body: %{"results" => results}}} when is_list(results) ->
        {:ok, Enum.flat_map(results, &normalize_result/1)}

      {:ok, %{status: status}} ->
        {:error, {:search_request_failed, status}}

      {:error, reason} ->
        {:error, {:search_request_failed, reason}}
    end
  end

  defp request_body(query, api_key) do
    %{
      api_key: api_key,
      query: query,
      search_depth: "advanced",
      max_results: 10,
      include_answer: false
    }
  end

  defp normalize_result(%{"url" => source_url} = result) when is_binary(source_url) do
    case URI.parse(source_url) do
      %URI{scheme: "https", host: host} when is_binary(host) and host != "" ->
        [
          %{
            source_url: source_url,
            title: result["title"] || host,
            evidence:
              result["content"] || result["raw_content"] || "Public company signal to review."
          }
        ]

      _uri ->
        []
    end
  end

  defp normalize_result(_result), do: []
end
