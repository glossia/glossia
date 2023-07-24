defmodule Glossia.Translations do
  use Boundary, deps: [Glossia.VM, Glossia.VCS, Glossia.Projects], exports: []

  # Modules
  alias Glossia.Translations.Translate

  # Public

  @moduledoc """
  The `Glossia.Translations` context provides an interface to manage translations.
  """
  @spec translate([
          {:commit_sha, String.t()},
          {:repository_id, String.t()},
          {:vcs, atom()}
        ]) ::
          {:ok, nil} | {:error, any()}
  def translate(attrs) do
    attrs
    |> Enum.into(%{})
    |> Translate.new()
    |> Oban.insert()
    |> case do
      {:ok, _} -> {:ok, nil}
      {:error, error} -> {:error, error}
    end
  end
end
