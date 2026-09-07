defmodule Glossia.HTTP do
  @moduledoc false

  def new(opts \\ []) do
    opts
    |> Keyword.put_new(:finch, Glossia.Finch)
    |> Req.new()
    |> OpentelemetryReq.attach(propagate_trace_headers: true)
  end
end
