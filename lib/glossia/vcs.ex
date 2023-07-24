defmodule Glossia.VCS do
  @moduledoc """
  """
  @type t :: :github

  @callback get_file_content(
              repository_id :: String.t(),
              path :: String.t()
            ) :: {:ok, String.t()} | {:error, atom()}

  @callback process_webhook(event :: String.t(), payload :: map()) :: nil

  @spec process_webhook(
          event :: String.t(),
          payload :: map(),
          vcs :: t()
        ) :: nil
  def process_webhook(event, payload, vcs) do
    case vcs do
      :github ->
        Glossia.VCS.Github.process_webhook(event, payload)
    end
  end
end
