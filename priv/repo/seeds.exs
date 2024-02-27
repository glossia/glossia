alias Glossia.Repo
alias Glossia.Accounts, as: Accounts
alias Glossia.Accounts.Account
alias Glossia.ContentSources, as: ContentSources
alias Glossia.ContentSources.ContentSource

organization =
  Repo.get_by(Account, handle: "glossia")
  |> case do
    nil ->
      {:ok, organization} = Accounts.register_organization(%{handle: "glossia"})
      organization

    organization ->
      organization
  end

organization = organization |> Repo.preload(:account)

content_source =
  Repo.get_by(ContentSource,
    id_in_content_platform: "glossia/modulex",
    content_platform: :github
  )
  |> case do
    nil ->
      {:ok, content_source} =
        ContentSources.create_content_source(%{
          id_in_content_platform: "glossia/glossia",
          content_platform: :github,
          account_id: organization.account.id
        })

      content_source

    content_source ->
      content_source
  end
