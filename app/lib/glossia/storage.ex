defmodule Glossia.Storage do
  @moduledoc """
  Thin wrapper around ExAws.S3 for file storage operations.
  """

  require OpenTelemetry.Tracer, as: Tracer

  @doc """
  Uploads content to the given path in the configured bucket.

  ## Options

    * `:content_type` - the MIME type of the content (default: `"application/octet-stream"`)

  """
  def upload(path, content, opts \\ []) do
    Tracer.with_span "glossia.storage.upload" do
      content_type = Keyword.get(opts, :content_type, "application/octet-stream")

      Tracer.set_attributes([
        {"glossia.storage.path", to_string(path)},
        {"glossia.storage.content_type", to_string(content_type)}
      ])

      bucket()
      |> ExAws.S3.put_object(path, content, content_type: content_type)
      |> ExAws.request()
    end
  end

  @doc """
  Checks whether the object at the given path exists in the configured bucket.

  Returns `{:ok, headers}` if the object exists, `{:error, reason}` otherwise.
  """
  def head(path) do
    Tracer.with_span "glossia.storage.head" do
      Tracer.set_attributes([{"glossia.storage.path", to_string(path)}])

      bucket()
      |> ExAws.S3.head_object(path)
      |> ExAws.request()
    end
  end

  @doc """
  Downloads the object at the given path from the configured bucket.

  Returns `{:ok, %{body: binary}}` on success.
  """
  def download(path) do
    Tracer.with_span "glossia.storage.download" do
      Tracer.set_attributes([{"glossia.storage.path", to_string(path)}])

      bucket()
      |> ExAws.S3.get_object(path)
      |> ExAws.request()
    end
  end

  @doc """
  Deletes the object at the given path from the configured bucket.
  """
  def delete(path) do
    Tracer.with_span "glossia.storage.delete" do
      Tracer.set_attributes([{"glossia.storage.path", to_string(path)}])

      bucket()
      |> ExAws.S3.delete_object(path)
      |> ExAws.request()
    end
  end

  @doc """
  Generates a presigned URL for the given path.

  ## Options

    * `:expires_in` - URL expiry in seconds (default: `3600`)
    * `:method` - HTTP method (default: `:get`)

  """
  def presigned_url(path, opts \\ []) do
    Tracer.with_span "glossia.storage.presigned_url" do
      expires_in = Keyword.get(opts, :expires_in, 3600)
      method = Keyword.get(opts, :method, :get)

      Tracer.set_attributes([
        {"glossia.storage.path", to_string(path)},
        {"glossia.storage.method", to_string(method)},
        {"glossia.storage.expires_in", expires_in}
      ])

      config = ExAws.Config.new(:s3)
      ExAws.S3.presigned_url(config, method, bucket(), path, expires_in: expires_in)
    end
  end

  @doc """
  Returns the configured bucket name.
  """
  def bucket do
    Application.get_env(:glossia, __MODULE__)[:bucket]
  end
end
