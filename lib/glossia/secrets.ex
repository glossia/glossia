defmodule Glossia.Secrets do
  @secrets_env_key :secrets

  def get_in(keys) when is_list(keys) do
    secrets() |> get_in(keys)
  end

  defp secrets do
    Application.get_env(:glossia, @secrets_env_key)
  end

  def load() do
    env = Application.get_env(:glossia, :env)
    secrets = if [:prod, :can] |> Enum.member?(Application.get_env(:glossia, :env)) do
      EncryptedSecrets.read!(System.fetch_env!("MASTER_KEY"))
    else
      EncryptedSecrets.read!()
    end

    Application.put_env(:glossia, @secrets_env_key, secrets[env])
  end
end
