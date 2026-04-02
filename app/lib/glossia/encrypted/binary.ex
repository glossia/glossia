defmodule Glossia.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: Glossia.Vault
end
