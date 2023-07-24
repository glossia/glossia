alias Glossia.Repo
alias Glossia.Accounts
alias Glossia.Accounts.Account
alias Glossia.Projects
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

project =
  Repo.get_by(Project, repository_id: "glossia/glossia", vcs: :github)
  |> case do
    nil ->
      {:ok, project} =
        Projects.create_project(%{
          handle: "glossia",
          repository_id: "glossia/glossia",
          vcs: :github,
          account_id: organization.id
        })

      project

    project ->
      project
  end
