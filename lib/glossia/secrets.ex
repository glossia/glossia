defmodule Glossia.Secrets do
  @secrets_env_key :secrets

  def get_in(keys) when is_list(keys) do
    secrets() |> get_in(keys)
  end

  defp secrets do
    Application.get_env(:glossia, @secrets_env_key)
  end

  def load(env \\ Application.get_env(:glossia, :env)) do
    secrets =
      if System.get_env("MASTER_KEY") do
        {:ok, cwd} = File.cwd()
        path = Path.join([cwd, "../priv/secrets/secrets.yml.enc"])
        EncryptedSecrets.read!(System.fetch_env!("MASTER_KEY"), path)
      else
        EncryptedSecrets.read!()
      end

    Application.put_env(:glossia, @secrets_env_key, secrets[env])
  end
end
