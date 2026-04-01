defmodule Glossia.Accounts.LLMModel do
  use Glossia.Schema
  import Ecto.Changeset

  @compile {:no_warn_undefined, [LLMDB]}

  @derive {
    Flop.Schema,
    filterable: [:handle, :model],
    sortable: [:handle, :model, :inserted_at],
    default_order: %{order_by: [:handle], order_directions: [:asc]}
  }

  schema "llm_models" do
    field :handle, :string
    field :model, :string
    field :api_key, Glossia.Encrypted.Binary

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :created_by, Glossia.Accounts.User

    timestamps()
  end

  def changeset(model_struct, attrs) do
    model_struct
    |> cast(attrs, [:handle, :model, :api_key])
    |> validate_required([:handle, :model, :api_key])
    |> validate_format(:handle, ~r/^[a-z][a-z0-9-]*$/,
      message: "must start with a letter and contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(:handle, min: 2, max: 64)
    |> validate_format(:model, ~r/^[a-z0-9_-]+:.+$/,
      message: "must be in provider:model format (e.g. anthropic:claude-sonnet-4-20250514)"
    )
    |> unique_constraint([:account_id, :handle])
  end

  def update_changeset(model_struct, attrs) do
    model_struct
    |> cast(attrs, [:handle, :model, :api_key])
    |> validate_required([:handle, :model])
    |> validate_format(:handle, ~r/^[a-z][a-z0-9-]*$/,
      message: "must start with a letter and contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(:handle, min: 2, max: 64)
    |> validate_format(:model, ~r/^[a-z0-9_-]+:.+$/,
      message: "must be in provider:model format (e.g. anthropic:claude-sonnet-4-20250514)"
    )
    |> unique_constraint([:account_id, :handle])
  end

  @doc """
  Returns a list of `{label, value}` tuples for all available models,
  grouped by provider, suitable for use in a select dropdown.
  """
  def available_models do
    LLMDB.providers()
    |> Enum.sort_by(& &1.id)
    |> Enum.map(fn provider ->
      models =
        LLMDB.models(provider.id)
        |> Enum.reject(& &1.deprecated)
        |> Enum.sort_by(& &1.id)
        |> Enum.map(fn m ->
          id = "#{provider.id}:#{m.id}"
          {m.name || m.id, id}
        end)

      {provider.name || to_string(provider.id), models}
    end)
    |> Enum.reject(fn {_name, models} -> models == [] end)
  end
end
