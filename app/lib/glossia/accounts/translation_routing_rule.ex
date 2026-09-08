defmodule Glossia.Accounts.TranslationRoutingRule do
  @moduledoc """
  Ordered translation-model routing rule for an account.

  A rule fires when its `target_locale` matches the locale being translated
  into. A `nil` `target_locale` matches any locale, which lets a rule act as a
  catch-all inside the ordered list. Resolution is first match wins; a request
  that hits no rule falls back to the account's default `LLMModel`.

  Source-locale matching is intentionally out of scope for v1: the translation
  payload does not yet carry a source locale code, so adding the field to this
  schema would advertise a match condition that can never fire. Introduce it as
  an additive column once the source locale is threaded through the pipeline.
  """
  use Glossia.Schema
  import Ecto.Changeset

  schema "translation_routing_rules" do
    field :position, :integer
    field :target_locale, :string

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :llm_model, Glossia.Accounts.LLMModel

    timestamps()
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [:position, :target_locale, :llm_model_id])
    |> update_change(:target_locale, &normalize_locale/1)
    |> validate_required([:position, :llm_model_id])
    |> validate_format(:target_locale, ~r/^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*$/,
      message: "must be a locale code like es or zh-Hans"
    )
    |> assoc_constraint(:llm_model)
    |> unique_constraint([:account_id, :position],
      name: :translation_routing_rules_account_position_index
    )
  end

  defp normalize_locale(nil), do: nil

  defp normalize_locale(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
