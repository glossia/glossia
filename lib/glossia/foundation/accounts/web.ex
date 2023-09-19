defmodule Glossia.Foundation.Accounts.Web do
  use Boundary,
    deps: [
      Glossia.Foundation.Accounts.Core,
      Glossia.Foundation.Auth.Core,
      Glossia.Foundation.Projects.Core,
      Glossia.Foundation.Analytics.Core
    ],
    exports: [Controllers.AuthController, Resources, Policies, Auth, Helpers.Auth]
  @behaviour __MODULE__.Behaviour

  defdelegate user_authenticated?(conn), to: __MODULE__.Helpers.Auth
  defdelegate authenticated_user(conn), to: __MODULE__.Helpers.Auth

  defmodule Behaviour do
    @callback user_authenticated?(Plug.Conn.t()) :: boolean
    @callback authenticated_user(Plug.Conn.t()) :: Glossia.Foundation.Accounts.Core.Models.User.t() | nil
  end
end
