defmodule GlossiaWeb.DashboardSocial do
  @moduledoc "Public branding shared by every dashboard route, without private page content."
  alias Glossia.OgImage

  @sections %{
    account: "Projects",
    voice: "Voice",
    voice_version: "Voice",
    voice_suggestion_new: "Voice",
    glossary: "Terminology",
    glossary_version: "Terminology",
    glossary_entry: "Terminology",
    glossary_entry_new: "Terminology",
    glossary_suggestion_new: "Terminology",
    discussion_show: "Suggestions",
    project: "Overview",
    project_translations: "Translations",
    project_session: "Translation session",
    project_settings: "Project settings",
    project_analytics: "Analytics",
    project_analytics_settings: "Analytics settings",
    project_new: "New project",
    members: "Members"
  }

  def image_url(account, project, action) do
    section = Map.get(@sections, action, "Settings")

    cond do
      account.visibility != "public" ->
        OgImage.marketing_url(%{title: "Your words. Every language.", category: "Workspace"})

      project != nil ->
        attrs = %{
          title: project.name,
          description: "#{account.handle}/#{project.handle} · #{section}",
          category: section,
          project_avatar: project.avatar_url,
          project_avatar_version: project.updated_at
        }

        OgImage.project_url(account.handle, project.handle, attrs)

      true ->
        OgImage.account_url(account.handle, %{
          title: account.handle,
          description: "A shared home for your words, in every language.",
          category: section
        })
    end
  end
end
