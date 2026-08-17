defmodule Glossia.Sandbox.Output do
  @moduledoc false

  def truncate(output, limit)
      when is_binary(output) and is_integer(limit) and byte_size(output) > limit do
    output
    |> binary_part(0, limit)
    |> valid_prefix()
  end

  def truncate(output, _limit), do: output

  defp valid_prefix(value) do
    if String.valid?(value) do
      value
    else
      value |> binary_part(0, byte_size(value) - 1) |> valid_prefix()
    end
  end
end
