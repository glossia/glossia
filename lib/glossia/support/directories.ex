defmodule Glossia.Support.Directories do
  @priv :code.priv_dir(:glossia)

  def priv() do
    @priv |> List.to_string()
  end
end
