defmodule Glossia.Foundation.Application.Core do
  use Boundary, exports: [Gettext, SEO, Telemetry]
end
