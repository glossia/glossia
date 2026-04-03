defmodule Glossia.Events.NoopHandler do
  @moduledoc false

  @behaviour Glossia.Events.Handler

  @impl true
  def handle_event(_event), do: :ok
end
