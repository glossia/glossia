defmodule Glossia.Auditing.DefaultSink do
  @moduledoc false

  @behaviour Glossia.Auditing.Sink

  @impl true
  def list_events(_account_id, _opts \\ []), do: []
end
