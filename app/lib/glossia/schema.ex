defmodule Glossia.Schema do
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      @primary_key {:id, Uniq.UUID, version: 7, autogenerate: true}
      @foreign_key_type Uniq.UUID
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
