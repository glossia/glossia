defmodule Glossia.Validations do
  @moduledoc """
  Shared changeset validations reused across schemas.
  """

  import Ecto.Changeset

  @locale_regex ~r/^[a-z]{2}(-[A-Za-z]{2,})?$/
  @handle_regex ~r/^[a-z]([a-z0-9-]*[a-z0-9])?$/

  @doc """
  Validates that a field contains a valid locale string (BCP 47-like).

  Accepts values like "en", "ja", "es-MX", "pt-BR".
  """
  def validate_locale(changeset, field) do
    changeset
    |> validate_format(field, @locale_regex,
      message: "must be a valid locale like 'en', 'ja', 'es-MX'"
    )
  end

  @doc """
  Validates that an array field contains only valid locale strings.

  Each element must match the same BCP 47-like pattern as `validate_locale/2`.
  """
  def validate_locales(changeset, field) do
    validate_change(changeset, field, fn _, values ->
      invalid =
        Enum.reject(values, fn v ->
          is_binary(v) and Regex.match?(@locale_regex, v)
        end)

      if invalid == [] do
        []
      else
        [{field, "contains invalid locales: #{Enum.join(invalid, ", ")}"}]
      end
    end)
  end

  @doc """
  Validates that a field contains a valid handle.

  Must start with a letter and contain only lowercase letters, numbers, and hyphens.
  """
  def validate_handle(changeset, field, opts \\ []) do
    min = Keyword.get(opts, :min, 2)
    max = Keyword.get(opts, :max, 39)

    changeset
    |> validate_format(field, @handle_regex,
      message: "must start with a letter and contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(field, min: min, max: max)
  end
end
