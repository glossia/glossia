defmodule Glossia.Translations do
  # Modules
  alias Glossia.Translations.TranslateBuild

  # Public

  @moduledoc """
  The `Glossia.Translations` context provides an interface to manage translations.
  """
  @spec translate(String.t(), String.t(), String.t(), Glossia.VCS.t()) ::
          {:ok, nil} | {:error, any()}
  def translate(commit_sha, repository_id, installation_id, vcs) do
    %{
      commit_sha: commit_sha,
      repository_id: repository_id,
      installation_id: installation_id,
      vcs: vcs
    }
    |> TranslateBuild.new()
    |> Oban.insert()
    |> case do
      {:ok, _} -> {:ok, nil}
      {:error, error} -> {:error, error}
    end
  end
end
