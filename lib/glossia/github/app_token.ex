defmodule Glossia.GitHub.AppToken do
  use Joken.Config, default_signer: :github

  def token_config do
    app_id = Glossia.Secrets.get_in([:github, :app, :id])

    %{}

    # issued at time, 60 seconds in the past to allow for clock drift
    |> add_claim("iat", fn -> (DateTime.utc_now() |> DateTime.to_unix()) - 60 end)

    # JWT expiration time (10 minute maximum)
    |> add_claim("exp", fn -> (DateTime.utc_now() |> DateTime.to_unix()) + 10 * 60 end)

    # GitHub App's identifier
    |> add_claim("iss", fn -> app_id end)
  end
end
