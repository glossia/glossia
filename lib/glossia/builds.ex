defmodule Glossia.Builds do
  use Boundary, deps: [], exports: []

  @spec run(
          attrs :: %{
            env: map(),
            update_status_cb: Glossia.Builds.VirtualMachine.update_status_cb_t()
          }
        ) ::
          :ok

  def run(%{env: env, update_status_cb: update_status_cb}) do
    Glossia.Builds.VirtualMachine.run(%{env: env, update_status_cb: update_status_cb})
  end
end
