alias Glossia.Repo
alias Glossia.Accounts, as: Accounts
alias Glossia.Accounts.Account
alias Glossia.Projects, as: Projects
alias Glossia.Projects.Project

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

project =
  Repo.get_by(Project, content_source_id: "glossia/modulex", content_source_platform: :github)
  |> case do
    nil ->
      {:ok, project} =
        Projects.create_project(%{
          handle: "glossia",
          content_source_id: "glossia/glossia",
          content_source_platform: :github,
          account_id: organization.account.id
        })

      project

    project ->
      project
  end
