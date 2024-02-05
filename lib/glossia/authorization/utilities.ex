defmodule Glossia.Authorization.Utilities do
  @moduledoc false

  def resolve_param_or_callback(conn, fun) when is_function(fun, 1) do
    fun.(conn)
  end

  def resolve_param_or_callback(conn, {module, fun}) when is_atom(module) and is_atom(fun) do
    apply(module, fun, [conn])
  end

  def resolve_param_or_callback(_conn, value), do: value

  def valid_getter?(fun) when is_function(fun, 1), do: true
  def valid_getter?({module, fun}) when is_atom(module) and is_atom(fun), do: true
  def valid_getter?(_), do: false
end
