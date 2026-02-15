defmodule Glossia.ChangesetErrors do
  @moduledoc false

  @spec to_map(Ecto.Changeset.t()) :: map()
  def to_map(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, &interpolate_error/1)
  end

  @spec to_inline_string(Ecto.Changeset.t()) :: String.t()
  def to_inline_string(%Ecto.Changeset{} = changeset) do
    changeset
    |> to_map()
    |> Enum.map_join(", ", fn {field, msgs} ->
      "#{field}: #{Enum.join(msgs, ", ")}"
    end)
  end

  defp interpolate_error({msg, opts}) do
    Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      atom_key =
        try do
          String.to_existing_atom(key)
        rescue
          ArgumentError -> nil
        end

      value =
        if is_atom(atom_key) do
          Keyword.get(opts, atom_key, key)
        else
          key
        end

      Kernel.to_string(value)
    end)
  end
end
