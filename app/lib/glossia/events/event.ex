defmodule Glossia.Events.Event do
  @moduledoc """
  Immutable domain event emitted by OSS mutation flows.
  """

  @enforce_keys [:name, :account, :user, :opts, :occurred_at]
  defstruct [:name, :account, :user, :opts, :occurred_at]

  @type t :: %__MODULE__{
          name: String.t(),
          account: struct(),
          user: struct() | nil,
          opts: keyword(),
          occurred_at: DateTime.t()
        }
end
