defmodule Glossia.TranslationRouting do
  @moduledoc """
  Ordered per-account routing rules that pick an LLM model based on the
  translation's target locale.

  A translation without an explicit model handle walks the rules in order and
  uses the first one whose `target_locale` matches (or whose `target_locale` is
  `nil`, which matches any locale). When no rule matches, resolution falls back
  to the account's default `LLMModel`.
  """

  import Ecto.Query

  alias Glossia.Accounts.{Account, LLMModel, TranslationRoutingRule, User}
  alias Glossia.Events
  alias Glossia.Repo

  def list_rules(%Account{} = account), do: list_rules(account.id)

  def list_rules(account_id) do
    Repo.all(
      from r in TranslationRoutingRule,
        where: r.account_id == ^account_id,
        order_by: [asc: r.position],
        preload: [:llm_model]
    )
  end

  def get_rule!(id, account_id) do
    Repo.one!(
      from r in TranslationRoutingRule,
        where: r.id == ^id and r.account_id == ^account_id,
        preload: [:llm_model]
    )
  end

  def get_rule(id, account_id) do
    Repo.one(
      from r in TranslationRoutingRule,
        where: r.id == ^id and r.account_id == ^account_id,
        preload: [:llm_model]
    )
  end

  @doc """
  Resolves the account's routing rules against a target locale and returns the
  matching `LLMModel`, or `nil` when no rule applies. The caller is expected to
  fall back to the account default in the `nil` case.
  """
  def resolve_model(%Account{} = account, target_locale) do
    resolve_model(account.id, target_locale)
  end

  def resolve_model(account_id, target_locale) do
    account_id
    |> list_rules()
    |> Enum.find(&matches?(&1, target_locale))
    |> case do
      nil -> nil
      rule -> rule.llm_model
    end
  end

  defp matches?(%TranslationRoutingRule{target_locale: nil}, _locale), do: true

  defp matches?(%TranslationRoutingRule{target_locale: rule_locale}, locale)
       when is_binary(locale) do
    String.downcase(rule_locale) == String.downcase(locale)
  end

  defp matches?(_rule, _locale), do: false

  def create_rule(%Account{} = account, %User{} = user, %LLMModel{} = model, attrs) do
    if model.account_id != account.id do
      raise ArgumentError, "cannot route to a model that belongs to a different account"
    end

    result =
      Repo.transaction(fn ->
        position = next_position(account.id)

        changeset =
          %TranslationRoutingRule{}
          |> TranslationRoutingRule.changeset(
            Map.merge(attrs, %{"position" => position, "llm_model_id" => model.id})
          )
          |> Ecto.Changeset.put_change(:account_id, account.id)

        case Repo.insert(changeset) do
          {:ok, rule} -> Repo.preload(rule, :llm_model)
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)

    with {:ok, rule} <- result do
      Events.emit("translation_routing_rule.created", account, user,
        resource_type: "translation_routing_rule",
        resource_id: to_string(rule.id),
        resource_path: "/#{account.handle}/-/settings/models/routing",
        summary:
          "Added routing rule → \"#{rule.llm_model.handle}\" (target: #{format_locale(rule.target_locale)})"
      )

      {:ok, rule}
    end
  end

  def update_rule(%Account{} = account, %User{} = user, %TranslationRoutingRule{} = rule, attrs) do
    if rule.account_id != account.id do
      raise ArgumentError, "cannot update a rule that belongs to a different account"
    end

    changeset =
      rule
      |> TranslationRoutingRule.changeset(
        Map.take(attrs, ["target_locale", "llm_model_id", :target_locale, :llm_model_id])
      )

    with {:ok, updated} <- Repo.update(changeset),
         updated <- Repo.preload(updated, :llm_model, force: true) do
      Events.emit("translation_routing_rule.updated", account, user,
        resource_type: "translation_routing_rule",
        resource_id: to_string(updated.id),
        resource_path: "/#{account.handle}/-/settings/models/routing",
        summary:
          "Updated routing rule → \"#{updated.llm_model.handle}\" (target: #{format_locale(updated.target_locale)})"
      )

      {:ok, updated}
    end
  end

  def delete_rule(%Account{} = account, %User{} = user, %TranslationRoutingRule{} = rule) do
    result =
      Repo.transaction(fn ->
        with {:ok, deleted} <- Repo.delete(rule) do
          renumber_positions(account.id)
          deleted
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)

    with {:ok, deleted} <- result do
      Events.emit("translation_routing_rule.deleted", account, user,
        resource_type: "translation_routing_rule",
        resource_id: to_string(deleted.id),
        resource_path: "/#{account.handle}/-/settings/models/routing",
        summary: "Removed routing rule"
      )

      {:ok, deleted}
    end
  end

  def move_rule(%Account{} = account, %User{} = user, %TranslationRoutingRule{} = rule, direction)
      when direction in [:up, :down] do
    result =
      Repo.transaction(fn ->
        rules =
          from(r in TranslationRoutingRule,
            where: r.account_id == ^account.id,
            order_by: [asc: r.position],
            lock: "FOR UPDATE"
          )
          |> Repo.all()

        index = Enum.find_index(rules, &(&1.id == rule.id))
        neighbor_index = if direction == :up, do: index - 1, else: index + 1

        cond do
          is_nil(index) -> Repo.rollback(:not_found)
          neighbor_index < 0 or neighbor_index >= length(rules) -> :noop
          true -> swap_positions(Enum.at(rules, index), Enum.at(rules, neighbor_index))
        end
      end)

    case result do
      {:ok, :noop} ->
        {:ok, rule}

      {:ok, _} ->
        Events.emit("translation_routing_rule.moved", account, user,
          resource_type: "translation_routing_rule",
          resource_id: to_string(rule.id),
          resource_path: "/#{account.handle}/-/settings/models/routing",
          summary: "Reordered routing rule (#{direction})"
        )

        {:ok, get_rule!(rule.id, account.id)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp swap_positions(a, b) do
    # Use a sentinel position outside the account's range so the unique
    # (account_id, position) index doesn't trip during the swap.
    sentinel = -1

    a_position = a.position
    b_position = b.position

    Repo.update_all(from(r in TranslationRoutingRule, where: r.id == ^a.id),
      set: [position: sentinel]
    )

    Repo.update_all(from(r in TranslationRoutingRule, where: r.id == ^b.id),
      set: [position: a_position]
    )

    Repo.update_all(from(r in TranslationRoutingRule, where: r.id == ^a.id),
      set: [position: b_position]
    )

    :ok
  end

  defp next_position(account_id) do
    Repo.one(
      from r in TranslationRoutingRule,
        where: r.account_id == ^account_id,
        select: coalesce(max(r.position), -1)
    )
    |> Kernel.+(1)
  end

  defp renumber_positions(account_id) do
    from(r in TranslationRoutingRule,
      where: r.account_id == ^account_id,
      order_by: [asc: r.position]
    )
    |> Repo.all()
    |> Enum.with_index()
    |> Enum.each(fn {rule, index} ->
      if rule.position != index do
        Repo.update_all(
          from(r in TranslationRoutingRule, where: r.id == ^rule.id),
          set: [position: index]
        )
      end
    end)
  end

  defp format_locale(nil), do: "any"
  defp format_locale(locale), do: locale
end
