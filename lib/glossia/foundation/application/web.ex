defmodule Glossia.Foundation.Application.Web do
  use Boundary

  def static_paths, do: ~w(assets fonts images schemas favicons robots.txt builder)
end
