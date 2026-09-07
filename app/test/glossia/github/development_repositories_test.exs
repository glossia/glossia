defmodule Glossia.Github.DevelopmentRepositoriesTest do
  use ExUnit.Case, async: false

  alias Glossia.Github.DevelopmentRepositories

  @tag :tmp_dir
  test "lists local development repositories in the project picker", %{tmp_dir: dir} do
    previous_routes = Application.get_env(:glossia, :dev_routes)
    previous_translations = Application.get_env(:glossia, Glossia.Translations, [])

    on_exit(fn ->
      Application.put_env(:glossia, :dev_routes, previous_routes)
      Application.put_env(:glossia, Glossia.Translations, previous_translations)
    end)

    git_dir = Path.join([dir, "dev-user", "demo", ".git"])
    File.mkdir_p!(git_dir)
    File.write!(Path.join(git_dir, "HEAD"), "ref: refs/heads/trunk\n")

    Application.put_env(:glossia, :dev_routes, true)
    Application.put_env(:glossia, Glossia.Translations, local_remotes_dir: dir)

    assert [repository] = DevelopmentRepositories.list()
    assert repository["full_name"] == "dev-user/demo"
    assert repository["name"] == "demo"
    assert repository["default_branch"] == "trunk"
    assert repository["development"] == true
    assert repository["owner"] == %{"login" => "dev-user"}
    assert is_integer(repository["id"])
  end
end
