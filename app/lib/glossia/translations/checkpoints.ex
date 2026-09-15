defmodule Glossia.Translations.Checkpoints do
  @moduledoc """
  Durable, seven-day checkpoints for locally validated translation segments.

  Keys include the account/project scope, effective credential, document input,
  context, segment, and repair attempt. Final document validation always runs
  again. Detached runners relay storage operations to the database-owning node.
  """
  import Ecto.Query
  alias Glossia.Repo

  def key(value),
    do:
      :crypto.hash(:sha256, :erlang.term_to_binary(value, [:deterministic]))
      |> Base.encode16(case: :lower)

  def fetch(nil, _key), do: nil
  def fetch(opts, key), do: relay(opts, :read, [key])
  def put(nil, _key, _result), do: :ok
  def put(opts, key, result), do: relay(opts, :write, [key, result])

  def read(key) do
    result =
      Repo.one(
        from c in "translation_segment_checkpoints",
          where: c.key == ^key and c.expires_at > ^DateTime.utc_now(),
          select: c.result
      )

    case result do
      %{"text" => text, "model" => model, "provider" => provider} ->
        %{text: text, model: model, provider: provider}

      _ ->
        nil
    end
  end

  def write(key, result) do
    Repo.insert_all(
      "translation_segment_checkpoints",
      [
        %{
          key: key,
          result: Map.take(result, [:text, :model, :provider]),
          expires_at: DateTime.add(DateTime.utc_now(), 7, :day)
        }
      ],
      on_conflict: {:replace, [:result, :expires_at]},
      conflict_target: [:key]
    )

    :ok
  end

  def prune do
    now = DateTime.utc_now()
    Repo.delete_all(from c in "translation_segment_checkpoints", where: c.expires_at < ^now)
    Repo.delete_all(from p in "translation_provider_pacing", where: p.expires_at < ^now)
    :ok
  end

  defp relay(opts, function, args) do
    target = Keyword.get(opts, :credential_node, node())

    if target == node(),
      do: apply(__MODULE__, function, args),
      else: :erpc.call(target, __MODULE__, function, args, 15_000)
  end
end
