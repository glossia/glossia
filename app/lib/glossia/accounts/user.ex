defmodule Glossia.Accounts.User do
  use Glossia.Schema
  import Ecto.Changeset

  # CLDR is a compile-time dependency. Keep its full locale inventory, including
  # explicit likely scripts/regions (en-Latn-US, zh-Hant-TW), as a literal lookup
  # rather than depending on a configured UI locale backend at runtime. Stored
  # tags retain only the subtags the user supplied; we never infer fluency.
  @fluent_language_tags Cldr.Locale.all_language_tags()
                        |> Enum.reject(fn {_name, tag} -> tag.language == "und" end)
                        |> Enum.flat_map(fn {_name, tag} ->
                          for script <- [nil, tag.script], territory <- [nil, tag.territory] do
                            canonical =
                              Cldr.LanguageTag.to_string(
                                %{tag | script: script, territory: territory},
                                false
                              )

                            {String.downcase(canonical), canonical}
                          end
                        end)
                        |> Map.new()

  schema "users" do
    field :email, :string
    field :name, :string
    field :avatar_url, :string
    field :bio, :string
    field :github_url, :string
    field :x_url, :string
    field :linkedin_url, :string
    field :mastodon_url, :string
    field :locale, :string
    field :fluent_languages, {:array, :string}, default: []
    field :super_admin, :boolean, default: false
    field :authentication_version, :integer, default: 0
    field :temporary_access_grant_id, :binary_id, virtual: true

    belongs_to :account, Glossia.Accounts.Account
    has_many :identities, Glossia.Accounts.Identity
    has_many :organization_memberships, Glossia.Accounts.OrganizationMembership
    has_many :user_roles, Glossia.Accounts.UserRole

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :avatar_url, :locale])
    |> validate_locale()
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:account_id)
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :avatar_url, :bio, :github_url, :x_url, :linkedin_url, :mastodon_url])
    |> validate_length(:name, max: 100)
    |> validate_length(:bio, max: 500)
    |> validate_url(:github_url)
    |> validate_url(:x_url)
    |> validate_url(:linkedin_url)
    |> validate_url(:mastodon_url)
    |> cast_fluent_languages(attrs)
  end

  def fluent_languages_changeset(user, attrs) do
    user
    |> change()
    |> cast_fluent_languages(attrs)
  end

  def locale_changeset(user, attrs) do
    user
    |> cast(attrs, [:locale])
    |> validate_locale()
  end

  defp cast_fluent_languages(changeset, attrs) do
    changeset =
      changeset
      |> cast(attrs, [:fluent_languages], empty_values: [])
      |> validate_length(:fluent_languages, max: 50)

    case fetch_change(changeset, :fluent_languages) do
      {:ok, nil} ->
        add_error(changeset, :fluent_languages, "must be an array of language tags")

      {:ok, languages} when length(languages) <= 50 ->
        canonical =
          Enum.map(languages, &Map.get(@fluent_language_tags, String.downcase(&1 || "")))

        if nil in canonical do
          add_error(changeset, :fluent_languages, "contains an unsupported language tag")
        else
          put_change(changeset, :fluent_languages, Enum.uniq(canonical))
        end

      _ ->
        changeset
    end
  end

  defp validate_locale(changeset) do
    validate_change(changeset, :locale, fn _field, locale ->
      if Glossia.I18n.supported?(locale) do
        []
      else
        [locale: "is not a language Glossia is available in"]
      end
    end)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if value == "" or is_nil(value) do
        []
      else
        if String.starts_with?(value, "https://") do
          []
        else
          [{field, "must start with https://"}]
        end
      end
    end)
  end
end
