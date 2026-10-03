defmodule Glossia.Decisions do
  @moduledoc """
  Resolves decision models independently of generative models. Public
  configuration participates in translation lockfiles; keys are resolved on
  the database-owning node only when an evaluation is needed.
  """

  alias Glossia.Decisions.Jev
  alias Glossia.LLMModels
  alias Glossia.Models.ModelIdentifier

  def configuration(account) do
    case LLMModels.default_model(account, "decision") do
      nil -> nil
      model -> Map.take(model, [:handle, :model, :base_url, :decision_min_score])
    end
  end

  def credential(account, handle) do
    case LLMModels.get_model_by_handle(handle, account.id) do
      %{category: "decision", api_key: key} = model when is_binary(key) and key != "" ->
        {:ok, Map.take(model, [:model, :api_key, :base_url, :decision_min_score])}

      _ ->
        {:error, :decision_model_not_found}
    end
  end

  def credential_on(target_node, account, handle) when target_node == node(),
    do: credential(account, handle)

  def credential_on(target_node, account, handle) do
    case :rpc.call(target_node, __MODULE__, :credential, [account, handle], 5_000) do
      {:badrpc, _reason} -> {:error, :decision_credential_relay_failed}
      result -> result
    end
  end

  def evaluate(account, configuration, state, questions, opts \\ []) do
    target_node = Keyword.get(opts, :credential_node) || node()

    with {:ok, credential} <- credential_on(target_node, account, configuration.handle),
         true <- Map.drop(credential, [:api_key]) == Map.drop(configuration, [:handle]) do
      case ModelIdentifier.provider(credential.model) do
        "typesafe" ->
          Jev.evaluate(
            credential.model,
            credential.api_key,
            credential.base_url,
            state,
            questions,
            opts
          )

        _ ->
          {:error, :unsupported_decision_provider}
      end
    else
      false -> {:error, :decision_configuration_changed}
      {:error, reason} -> {:error, reason}
    end
  end
end
