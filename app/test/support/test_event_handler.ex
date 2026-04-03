defmodule Glossia.TestEventHandler do
  @moduledoc false

  def handle_event(_event), do: :ok
  def list_events(_account_id, _opts \\ []), do: []
end
