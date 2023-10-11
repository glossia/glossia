defmodule Glossia.ContentSources do
  # Modules
  alias Glossia.ContentSources.GitHub

  # Behaviors
  @behaviour Glossia.ContentSources.ContentSource

  @doc """
  Given an atom representing the content source and its identifier, it returns a tuple
  with the content source module and an instance of it. If the content source can't be
  found, it returns `nil`.
  """
  @spec new(content_source :: atom(), id :: String.t()) :: module()
  def new(content_source_id, id) do
    content_source(content_source_id).new(id)
  end

  def new(content_source_id) do
    content_source(content_source_id).new()
  end

  # Glossia.ContentSources.ContentSource behavior

  @impl Glossia.ContentSources.ContentSource
  def get_content(content_source, content_id, content_version) do
    content_source(content_source.id).get_content(content_source, content_id, content_version)
  end

  @impl Glossia.ContentSources.ContentSource
  def generate_auth_token(content_source) do
    content_source(content_source.id).generate_auth_token(content_source)
  end

  @impl Glossia.ContentSources.ContentSource
  def get_most_recent_version(content_source) do
    content_source(content_source.id).get_most_recent_version(content_source)
  end

  @impl Glossia.ContentSources.ContentSource
  def update_content(content_source, opts) do
    content_source(content_source.id).update_content(content_source, opts)
  end

  @impl Glossia.ContentSources.ContentSource
  def get_content_branch_id(content_source, opts) do
    content_source(content_source.id).get_content_branch_id(content_source, opts)
  end

  @impl Glossia.ContentSources.ContentSource
  @spec should_localize?(content_source :: module(), version :: String.t()) :: boolean()
  def should_localize?(content_source, version) do
    content_source(content_source.id).should_localize?(content_source, version)
  end

  @impl Glossia.ContentSources.ContentSource
  def update_state(content_source, state, version, opts) do
    content_source(content_source.id).update_state(content_source, state, version, opts)
  end

  @impl Glossia.ContentSources.ContentSource
  def is_webhook_payload_valid?(content_source, req_headers, payload) do
    content_source(content_source.id).is_webhook_payload_valid?(
      content_source,
      req_headers,
      payload
    )
  end

  # Private

  @spec content_source(id :: atom()) :: module() | nil
  defp content_source(id) do
    content_sources()
    |> Enum.find(fn {content_source_id, _} -> content_source_id == id end)
    |> case do
      {_, module} -> module
      nil -> "Content source #{id} not found"
    end
  end

  defp content_sources() do
    [{:github, GitHub}]
  end
end
