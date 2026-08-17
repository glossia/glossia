defmodule Glossia.Quality.PageAddress do
  @moduledoc false

  def build(origin, logical_path) when is_binary(origin) and is_binary(logical_path) do
    origin = URI.parse(origin)
    logical_path = URI.parse(logical_path)

    origin
    |> append_path(logical_path.path)
    |> URI.to_string()
  end

  defp append_path(%URI{path: path} = origin, "/") when path in [nil, ""] do
    %URI{origin | path: "/"}
  end

  defp append_path(origin, "/"), do: origin
  defp append_path(origin, path), do: URI.append_path(origin, path)
end
