defmodule Glossia.Blog.Author do
  defstruct [:id, :name, :avatar, :linkedin, :mastodon, :x, :github]

  @authors %{
    "pedro" => %{
      id: "pedro",
      name: "Pedro Pinera Buendia",
      avatar: "https://unavatar.io/x/pepicrft",
      linkedin: "https://linkedin.com/in/pepicrft",
      mastodon: "https://mastodon.social/@pepicrft",
      x: "https://x.com/pepicrft",
      github: "https://github.com/pepicrft"
    }
  }

  def get!(id) do
    data = Map.fetch!(@authors, id)
    struct!(__MODULE__, data)
  end

  def all do
    Enum.map(Map.values(@authors), &struct!(__MODULE__, &1))
  end
end
