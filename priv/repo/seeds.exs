alias Glossia.Foundation.Database.Core.Repo
alias Glossia.Foundation.Accounts.Core, as: Accounts
alias Glossia.Foundation.Accounts.Core.Account
alias Glossia.Foundation.Projects.Core, as: Projects
alias Glossia.Foundation.Projects.Core.Models.Project

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
  Repo.get_by(Project, content_source_id: "glossia/glossia", content_source_platform: :github)
  |> case do
    nil ->
      {:ok, project} =
        Projects.create_project(%{
          handle: "glossia",
          content_source_id: "glossia/glossia",
          content_source_platform: :github,
          account_id: organization.id
        })

      project

    project ->
      project
  end
