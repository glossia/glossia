defmodule Glossia.VCS do
  @moduledoc """
  """
  @type t :: :github

  @callback get_file_content(
              repository_id :: String.t(),
              path :: String.t()
            ) :: {:ok, String.t()} | {:error, atom()}
end
