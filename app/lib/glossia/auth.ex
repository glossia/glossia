defmodule Glossia.Auth do
  def provider_config!(provider) do
    providers = Application.fetch_env!(:glossia, :oauth_providers)

    config =
      Keyword.get(providers, provider) ||
        raise ArgumentError, "unknown OAuth provider: #{inspect(provider)}"

    redirect_uri = GlossiaWeb.Endpoint.url() <> "/auth/#{provider}/callback"
    Keyword.put(config, :redirect_uri, redirect_uri)
  end

  def authorize_url(provider) do
    config = provider_config!(provider)
    config[:strategy].authorize_url(config)
  end

  def callback(provider, params, session_params) do
    config =
      provider
      |> provider_config!()
      |> Keyword.put(:session_params, session_params)

    config[:strategy].callback(config, params)
  end
end

defmodule Glossia.Auth.InvalidProviderError do
  defexception [:message, plug_status: 400]
end
