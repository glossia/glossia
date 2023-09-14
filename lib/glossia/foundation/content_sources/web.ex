defmodule Glossia.Foundation.ContentSources.Web do
  use Boundary, deps: [Glossia.Foundation.ContentSources.Core, Glossia.Foundation.Projects.Core], exports: [Plug, Controllers.GitHub.WebhookController]
end
