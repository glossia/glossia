defmodule Glossia.EventLog do
  defmodule Source do
    @moduledoc false

    @callback list_events(term(), keyword()) :: [map()]
  end

  def list_events(account_id, opts \\ []) do
    Glossia.Extensions.event_log().list_events(account_id, opts)
  end
end

defmodule Glossia.EventLog.Empty do
  @moduledoc false

  @behaviour Glossia.EventLog.Source

  @impl true
  def list_events(_account_id, _opts \\ []), do: []
end
