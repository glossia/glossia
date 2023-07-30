defmodule Glossia.Builds do
  use Boundary, deps: [], exports: []

  @spec run(
          attrs :: [
            env: map(),
            update_status_cb: (String.t(), atom() -> nil)
          ]
        ) ::
          {:ok, String.t()}

  def run(env: env, update_status_cb: update_status_cb) do
    Glossia.Builds.VirtualMachine.run(env: env, update_status_cb: update_status_cb)
  end
end
