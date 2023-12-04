defmodule Glossia.Secrets do
  @secrets_env_key :secrets
  @base_directory "priv/secrets"
  @secrets_file_location @base_directory <> "/secrets.yml.enc"
  @key_file_location @base_directory <> "/master.key"

  def get_in(keys) when is_list(keys) do
    secrets() |> get_in(keys)
  end

  defp secrets do
    Application.get_env(:glossia, @secrets_env_key)
  end

  def load(env \\ Application.get_env(:glossia, :env)) do
    secrets =
      if System.get_env("MASTER_KEY") do
        EncryptedSecrets.read!(System.fetch_env!("MASTER_KEY"), @key_file_location)
      else
        EncryptedSecrets.read!()
      end

    Application.put_env(:glossia, @secrets_env_key, secrets[env])
  end
end
