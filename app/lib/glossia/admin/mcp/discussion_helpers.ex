defmodule Glossia.Admin.MCP.DiscussionHelpers do
  @moduledoc false

  alias Glossia.Discussions
  alias Hermes.MCP.Error

  def fetch_discussion(id) when is_binary(id) do
    case Discussions.get_discussion(id) do
      nil -> {:error, Error.execution("Discussion not found")}
      discussion -> {:ok, discussion}
    end
  end

  def fetch_discussion(_), do: {:error, Error.execution("Discussion ID must be a string")}

  def changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
