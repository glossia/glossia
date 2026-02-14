defmodule Glossia.HTTP do
  @moduledoc false

  def new(opts \\ []) do
    Req.new(opts) |> OpentelemetryReq.attach(propagate_trace_headers: true)
  end
end
