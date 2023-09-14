defmodule Glossia.Foundation.Application.Web do
  use Boundary, top_level?: true, check: [in: false, out: false]

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def static_paths, do: ~w(assets fonts images schemas favicons robots.txt builder)
end
