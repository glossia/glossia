defmodule Glossia.Translations.DependencyDiff do
  @moduledoc """
  Diffs compatibility-normalized dependency trees by full ancestry.

  Only changed branches survive. Diagnostic detail refines a changed metadata
  fingerprint when both baselines recorded it; it never creates an invalidation
  by itself. Added, removed, null and false values remain distinguishable.
  """

  def diff(nil, nil), do: nil

  def diff(previous, current) do
    node = current || previous
    before = if previous, do: previous["metadata"] || %{}, else: %{}
    after_value = if current, do: current["metadata"] || %{}, else: %{}
    {fields, details} = metadata_changes(before, after_value, previous, current)
    previous_children = children_by_identity(previous)
    current_children = children_by_identity(current)

    children =
      keys(previous_children, current_children)
      |> Enum.map(&diff(previous_children[&1], current_children[&1]))
      |> Enum.reject(&is_nil/1)

    if (fields == [] and details == [] and children == [] and previous) && current do
      nil
    else
      %{
        "kind" => node["kind"],
        "label" => node["label"],
        "change" => change(previous != nil, current != nil),
        "fields" => fields,
        "children" => children ++ details,
        "aggregate_only" =>
          previous != nil and current != nil and fields != [] and
            (previous["details"] || %{}) == %{} and (current["details"] || %{}) != %{}
      }
    end
  end

  def field_count(nil), do: 0

  def field_count(node),
    do: length(node["fields"]) + Enum.sum(Enum.map(node["children"], &field_count/1))

  defp metadata_changes(before, after_value, previous, current) do
    Enum.reduce(keys(before, after_value), {[], []}, fn key, {fields, details} ->
      old? = Map.has_key?(before, key)
      new? = Map.has_key?(after_value, key)

      if old? == new? and before[key] == after_value[key] do
        {fields, details}
      else
        old_detail = previous && get_in(previous, ["details", key])
        new_detail = current && get_in(current, ["details", key])

        detail =
          if is_map(old_detail) and is_map(new_detail),
            do: detail_diff(key, old_detail, new_detail)

        if detail do
          {fields, details ++ [detail]}
        else
          {fields ++ [field(key, before[key], after_value[key], old?, new?)], details}
        end
      end
    end)
  end

  defp detail_diff(label, before, after_value) do
    keys = keys(before, after_value)

    {fields, children} =
      Enum.reduce(keys, {[], []}, fn key, {fields, children} ->
        old? = Map.has_key?(before, key)
        new? = Map.has_key?(after_value, key)
        old = before[key]
        new = after_value[key]

        cond do
          old? == new? and old == new ->
            {fields, children}

          (is_map(old) or not old?) and (is_map(new) or not new?) ->
            child = detail_diff(key, old || %{}, new || %{})
            child = if child, do: %{child | "change" => change(old?, new?)}
            {fields, children ++ List.wrap(child)}

          true ->
            {fields ++ [field(key, old, new, old?, new?)], children}
        end
      end)

    # A document's combined fingerprint is redundant when its changed sections
    # are known. Keep it as a fallback when a bounded detail snapshot cannot
    # explain the change (for example, an omitted section changed).
    fields =
      if children != [], do: Enum.reject(fields, &(&1["field"] == "content_hash")), else: fields

    if fields != [] or children != [] do
      %{
        "kind" => "detail",
        "label" => label,
        "change" => "changed",
        "fields" => fields,
        "children" => children,
        "aggregate_only" => false
      }
    end
  end

  defp field(key, before, after_value, old?, new?) do
    %{
      "field" => key,
      "before" => before,
      "after" => after_value,
      "before_present" => old?,
      "after_present" => new?,
      "change" => change(old?, new?),
      "fingerprint" => String.ends_with?(key, "_hash")
    }
  end

  defp children_by_identity(nil), do: %{}

  defp children_by_identity(node),
    do: Map.new(node["children"] || [], &{{&1["kind"], &1["label"]}, &1})

  defp keys(before, after_value),
    do: (Map.keys(before) ++ Map.keys(after_value)) |> Enum.uniq() |> Enum.sort()

  defp change(false, true), do: "added"
  defp change(true, false), do: "removed"
  defp change(_, _), do: "changed"
end
