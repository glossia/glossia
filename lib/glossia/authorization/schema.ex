defmodule Glossia.Authorization.Schema do
  @callback scope(query :: any, subject :: any, params :: %{atom => any}) :: any
end
