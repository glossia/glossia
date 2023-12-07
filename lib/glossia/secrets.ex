defmodule Glossia.Secrets do
  @secrets_env_key :secrets
  @base_directory "priv/secrets"
  @secrets_file_location @base_directory <> "/secrets.yml.enc"
  require Logger

  @spec get_in([...], any()) :: any()
  def get_in(keys, secrets \\ Glossia.Secrets.secrets()) when is_list(keys) do
    secrets |> Kernel.get_in(keys)
  end

  def secrets do
    Application.get_env(:glossia, @secrets_env_key)
  end

  def load(env \\ Application.get_env(:glossia, :env)) do
    Logger.info("Loading secrets for #{env} environment")
    secrets =
      if System.get_env("MASTER_KEY") do
        EncryptedSecrets.read!(System.fetch_env!("MASTER_KEY"), System.get_env("SECRETS_PATH", @secrets_file_location))
      else
        EncryptedSecrets.read!()
      end

    Application.put_env(:glossia, @secrets_env_key, secrets[env])
    secrets[env]
  end
end
