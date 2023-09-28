defmodule Glossia.Foundation.Utilities.Core.Directories do
  @priv :code.priv_dir(:glossia)

  def priv() do
    @priv |> List.to_string()
  end
end
