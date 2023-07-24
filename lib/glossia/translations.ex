defmodule Glossia.Translations do
  alias Glossia.Translations.TranslateBuild

  @moduledoc """
  The `Glossia.Translations` context provides an interface to manage translations.
  """
  @spec translate(String.t(), String.t(), Glossia.VCS.t()) :: {:ok, nil} | {:error, any()}
  def translate(commit_sha, repository_id, vcs) do
    %{commit_sha: commit_sha, repository_id: repository_id, vcs: vcs}
    |> TranslateBuild.new()
    |> Oban.insert()
    |> case do
      {:ok, _} -> {:ok, nil}
      {:error, error} -> {:error, error}
    end
  end
end
