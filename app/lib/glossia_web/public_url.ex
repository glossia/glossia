defmodule GlossiaWeb.PublicURL do
  @moduledoc """
  The application's configured public address, independent of the web endpoint.

  Background jobs can use `base_uri/0` as the context for
  `Phoenix.VerifiedRoutes.url/2` to build verified links without starting the
  endpoint or relying on its initialized URL and path state.
  """

  @doc """
  Returns the public base URI from the endpoint's runtime configuration.

  Explicit `:url` settings override the listener's scheme and port. Without
  overrides, HTTPS takes precedence over HTTP, falling back to localhost on
  HTTP port 80 when neither listener is configured. A configured path prefix
  is retained for verified routes.

  Configuration can be passed explicitly without changing application state.
  """
  def base_uri(config \\ Application.fetch_env!(:glossia, GlossiaWeb.Endpoint)) do
    url = Keyword.get(config, :url, [])

    {scheme, port} =
      cond do
        https = config[:https] -> {"https", https[:port] || 443}
        http = config[:http] -> {"http", http[:port] || 80}
        true -> {"http", 80}
      end

    %URI{
      scheme: url[:scheme] || scheme,
      host: url[:host] || "localhost",
      port: (url[:port] || port) |> to_string() |> String.to_integer(),
      path: if(url[:path] == "/", do: nil, else: url[:path])
    }
  end
end
