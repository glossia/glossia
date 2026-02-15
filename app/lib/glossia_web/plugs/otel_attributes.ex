defmodule GlossiaWeb.Plugs.OtelAttributes do
  @moduledoc """
  Sets OpenTelemetry span attributes for the authenticated user and selected
  subject (account handle from URL params).
  """

  require OpenTelemetry.Tracer, as: Tracer

  def init(opts), do: opts

  def call(conn, _opts) do
    if user = conn.assigns[:current_user] do
      Tracer.set_attributes([
        {"enduser.id", to_string(user.id)},
        {"enduser.email", user.email || ""}
      ])
    end

    if handle = conn.path_params["handle"] do
      Tracer.set_attributes([{"glossia.subject.handle", handle}])
    end

    conn
  end
end
