defmodule Glossia.Quality.Profile do
  use Glossia.Schema
  import Ecto.Changeset

  @maximum_locale_origins 20
  @maximum_captures 100
  @maximum_locale_bytes 64
  @maximum_seed_path_bytes 255

  schema "quality_profiles" do
    field :source_locale, :string
    field :locale_origins, :map, default: %{}
    field :seed_paths, {:array, :string}, default: ["/"]
    field :max_pages, :integer, default: 20

    belongs_to :project, Glossia.Accounts.Project

    timestamps()
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:project_id, :source_locale, :locale_origins, :seed_paths, :max_pages])
    |> validate_required([:project_id, :source_locale, :locale_origins, :seed_paths, :max_pages])
    |> validate_format(:source_locale, ~r/^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$/,
      message: "must be a valid locale like en or pt-BR"
    )
    |> validate_change(:source_locale, fn :source_locale, locale ->
      if byte_size(locale) <= @maximum_locale_bytes,
        do: [],
        else: [source_locale: "cannot exceed #{@maximum_locale_bytes} bytes"]
    end)
    |> validate_number(:max_pages, greater_than: 0, less_than_or_equal_to: 50)
    |> validate_locale_origins()
    |> validate_seed_paths()
    |> validate_capture_budget()
    |> unique_constraint(:project_id)
  end

  defp validate_locale_origins(changeset) do
    validate_change(changeset, :locale_origins, fn :locale_origins, origins ->
      source_locale = get_field(changeset, :source_locale)

      cond do
        not is_map(origins) or map_size(origins) < 1 ->
          [locale_origins: "must contain a website URL"]

        map_size(origins) > @maximum_locale_origins ->
          [locale_origins: "cannot contain more than #{@maximum_locale_origins} locales"]

        not Map.has_key?(origins, source_locale) ->
          [locale_origins: "must contain the source locale"]

        true ->
          Enum.flat_map(origins, fn {locale, origin} ->
            validate_locale_origin(locale, origin)
          end)
      end
    end)
  end

  defp validate_locale_origin(locale, origin) when is_binary(locale) and is_binary(origin) do
    uri = URI.parse(String.trim(origin))

    cond do
      not Regex.match?(~r/^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$/, locale) ->
        [locale_origins: "contains an invalid locale"]

      byte_size(locale) > @maximum_locale_bytes ->
        [locale_origins: "contains a locale longer than #{@maximum_locale_bytes} bytes"]

      uri.scheme not in ["http", "https"] or is_nil(uri.host) ->
        [locale_origins: "contains an invalid web address"]

      uri.userinfo || uri.query || uri.fragment ->
        [locale_origins: "web addresses cannot contain credentials, queries, or fragments"]

      true ->
        []
    end
  end

  defp validate_locale_origin(_locale, _origin),
    do: [locale_origins: "must map locales to web addresses"]

  defp validate_seed_paths(changeset) do
    validate_change(changeset, :seed_paths, fn :seed_paths, paths ->
      cond do
        not is_list(paths) or paths == [] ->
          [seed_paths: "must contain at least one path"]

        length(paths) > 50 ->
          [seed_paths: "cannot contain more than 50 paths"]

        Enum.any?(paths, &(is_binary(&1) and byte_size(&1) > @maximum_seed_path_bytes)) ->
          [seed_paths: "cannot contain paths longer than #{@maximum_seed_path_bytes} bytes"]

        Enum.any?(paths, &(not valid_seed_path?(&1))) ->
          [seed_paths: "must contain only absolute paths without queries or fragments"]

        true ->
          []
      end
    end)
  end

  defp valid_seed_path?(path) when is_binary(path) do
    case URI.parse(String.trim(path)) do
      %URI{scheme: nil, host: nil, path: "/" <> _, query: nil, fragment: nil} -> true
      _ -> false
    end
  end

  defp valid_seed_path?(_path), do: false

  defp validate_capture_budget(changeset) do
    origins = get_field(changeset, :locale_origins)
    paths = get_field(changeset, :seed_paths)
    max_pages = get_field(changeset, :max_pages)

    if is_map(origins) and is_list(paths) and is_integer(max_pages) and max_pages > 0 and
         map_size(origins) * min(length(paths), max_pages) > @maximum_captures do
      add_error(
        changeset,
        :max_pages,
        "would inspect more than #{@maximum_captures} pages across all locales"
      )
    else
      changeset
    end
  end
end
