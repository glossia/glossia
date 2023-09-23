defmodule Glossia.Foundation.Analytics.Core do
  use Boundary, deps: [Glossia.Foundation.Utilities.Core], exports: [Tracker]
end
