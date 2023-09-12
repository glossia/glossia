defmodule Glossia.Foundation.Application.Web do
  use Boundary, exports: [Plugs.RawBodyPassthroughPlug, Plugs.AttackPlug]

  def static_paths, do: ~w(assets fonts images schemas favicons robots.txt builder)
end
