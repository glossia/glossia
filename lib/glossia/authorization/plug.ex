defmodule Glossia.Authorization.Plug do
  @behaviour Plug
  alias Glossia.Authorization.Utilities

  def init(opts \\ []) do
    policy = Keyword.get(opts, :policy)
    action = Keyword.get(opts, :action)
    subject = Keyword.get(opts, :subject)
    params = Keyword.get(opts, :params, [])
    fallback = Keyword.get(opts, :fallback)

    # Policy must be defined
    if is_nil(policy), do: raise(ArgumentError, "#{inspect(__MODULE__)} :policy option required")

    # Action must be defined
    if is_nil(action),
      do:
        raise(
          ArgumentError,
          "#{inspect(__MODULE__)} :action option is required"
        )

    # Subject can be nil or a getter function
    unless is_nil(subject) || Utilities.valid_getter?(subject),
      do:
        raise(
          ArgumentError,
          "#{inspect(__MODULE__)} :subject option #{inspect(subject)} is invalid"
        )

    unless is_nil(fallback) or is_atom(fallback),
      do: raise(ArgumentError, "#{inspect(__MODULE__)} :fallback option must be a plug module")

    # Plug 1.0 through 1.3.2 doesn't support returning maps from init/1
    # See https://github.com/schrockwell/bodyguard/issues/52
    {fallback,
     [
       policy: policy,
       action: action,
       subject: subject,
       params: params
     ]}
  end

  def call(conn, {nil, opts}) do
    Glossia.Authorization.permit!(
      opts[:policy],
      Utilities.resolve_param_or_callback(conn, opts[:action]),
      Utilities.resolve_param_or_callback(conn, opts[:subject]),
      Utilities.resolve_param_or_callback(conn, opts[:params])
    )

    conn
  end

  def call(conn, {fallback, opts}) do
    case Glossia.Authorization.permit(
           opts[:policy],
           Utilities.resolve_param_or_callback(conn, opts[:action]),
           Utilities.resolve_param_or_callback(conn, opts[:subject]),
           Utilities.resolve_param_or_callback(conn, opts[:params])
         ) do
      :ok ->
        conn

      error ->
        conn
        |> fallback.call(error)
        |> Plug.Conn.halt()
    end
  end
end
