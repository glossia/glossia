defmodule Glossia.Authorization.Policy do
  @type action :: atom | String.t()
  @type auth_result :: :ok | :error | {:error, reason :: any} | true | false
  @callback authorize(action :: action, subject :: any, params :: %{atom => any} | any) ::
              auth_result

  @callback authorize(action :: action, subject :: any, params :: %{atom => any} | any) ::
              auth_result
end
