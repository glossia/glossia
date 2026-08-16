defmodule Glossia.Accounts.LLMModel do
  use Glossia.Schema
  import Ecto.Changeset

  alias Glossia.Models.ModelIdentifier

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
    field :base_url, :string
    field :default, :boolean, default: false

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :created_by, Glossia.Accounts.User

    timestamps()
  end

  def changeset(model_struct, attrs, opts \\ []) do
    required =
      if Keyword.get(opts, :require_api_key, true),
        do: [:handle, :model, :api_key],
        else: [:handle, :model]

    model_struct
    |> cast(attrs, [:handle, :model, :api_key, :base_url, :default])
    |> update_change(:model, &ModelIdentifier.normalize/1)
    |> update_change(:base_url, &normalize_base_url/1)
    |> validate_change(:base_url, &validate_base_url/2)
    |> validate_required(required)
    |> validate_format(:handle, ~r/^[a-z][a-z0-9-]*$/,
      message: "must start with a letter and contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(:handle, min: 2, max: 64)
    |> validate_format(:model, ~r/^[a-z0-9_-]+\/.+$/,
      message: "must be in provider/model format (e.g. anthropic/claude-sonnet-4-20250514)"
    )
    |> unique_constraint([:account_id, :handle],
      error_key: :handle,
      message: "has already been taken"
    )
    |> unique_constraint(:default,
      name: :llm_models_one_default_per_account,
      message: "another model is already the default for this account"
    )
  end

  # Treat blank base URLs as "use the provider default endpoint" and trim
  # surrounding whitespace. The resolver emits nil for these so Condukt routes
  # to the provider's native base URL.
  defp normalize_base_url(nil), do: nil

  defp normalize_base_url(url) when is_binary(url) do
    case String.trim(url) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  # validate_change/3 calls this as fun.(field, value) and expects a list of
  # {field, message} tuples. Only enforce a scheme when a value was actually
  # provided. A path such as "http://api.together.ai/v1" or an in-cluster
  # service like "http://glossia-bifrost.glossia.svc.cluster.local:8080/v1" is
  # fine; a bare hostname is not a usable gateway URL.
  defp validate_base_url(_field, nil), do: []
  defp validate_base_url(_field, ""), do: []

  defp validate_base_url(field, url) do
    if String.starts_with?(String.downcase(String.trim(url)), ["http://", "https://"]) do
      []
    else
      [{field, {"must start with http:// or https://", []}}]
    end
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
        |> Enum.reject(&unavailable?/1)
        |> Enum.sort_by(& &1.id)
        |> Enum.map(fn m ->
          id = ModelIdentifier.join(provider.id, m.id)
          {m.name || m.id, id}
        end)

      {provider.name || to_string(provider.id), models}
    end)
    |> Enum.reject(fn {_name, models} -> models == [] end)
  end

  defp unavailable?(model) do
    status =
      case model.extra do
        extra when is_map(extra) -> Map.get(extra, :status) || Map.get(extra, "status")
        _ -> nil
      end

    model.deprecated or model.retired or status in ["deprecated", "retired"]
  end
end
