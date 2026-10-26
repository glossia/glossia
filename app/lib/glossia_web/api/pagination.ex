defmodule GlossiaWeb.Api.Pagination do
  @moduledoc false

  def params(params) do
    with {:ok, page} <- integer(params["page"] || 1, 1, 10_000),
         {:ok, page_size} <- integer(params["page_size"] || 20, 1, 50) do
      {:ok, %{"page" => page, "page_size" => page_size}}
    end
  end

  def integer(value, min, max) do
    case Ecto.Type.cast(:integer, value) do
      {:ok, number} when is_integer(number) and number >= min and number <= max -> {:ok, number}
      _ -> {:error, :invalid_parameters}
    end
  end
end
