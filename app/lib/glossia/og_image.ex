defmodule Glossia.OgImage do
  @moduledoc """
  Lazy Open Graph image generation.

  Computes a content-addressed hash from page attributes, checks S3 for a cached
  version, generates via ChromicPDF if missing, and returns JPEG bytes.
  """

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  defp template_path, do: Path.join(:code.priv_dir(:glossia), "og_image/template.html.eex")

  # Bump this version whenever the template design changes to force
  # re-generation of all cached images in production.
  @design_version 10

  @doc """
  Returns a SHA-256 hash (base64url, no padding) of the given attributes map.

  Includes an internal design version so that template changes automatically
  invalidate the S3 cache.
  """
  def hash(attrs) when is_map(attrs) do
    attrs
    |> Map.put(:v, @design_version)
    |> JSON.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Returns the absolute URL for a marketing OG image.
  """
  def marketing_url(attrs) do
    if enabled?() do
      h = hash(attrs)
      category = attrs[:category] || attrs["category"] || "page"
      token = sign_attrs(attrs)
      GlossiaWeb.Endpoint.url() <> "/og/marketing/#{category}/#{h}.jpg?d=#{token}"
    end
  end

  @doc """
  Returns the absolute URL for an account OG image.
  """
  def account_url(handle, attrs) do
    if enabled?() do
      h = hash(attrs)
      token = sign_attrs(attrs)
      GlossiaWeb.Endpoint.url() <> "/og/app/#{handle}/#{h}.jpg?d=#{token}"
    end
  end

  @doc """
  Returns the absolute URL for a project OG image.
  """
  def project_url(handle, project, attrs) do
    if enabled?() do
      h = hash(attrs)
      token = sign_attrs(attrs)
      GlossiaWeb.Endpoint.url() <> "/og/app/#{handle}/#{project}/#{h}.jpg?d=#{token}"
    end
  end

  @doc """
  Signs attrs into a compact URL-safe token. Valid for 30 days.
  """
  def sign_attrs(attrs) do
    Phoenix.Token.sign(GlossiaWeb.Endpoint, "og-image", attrs)
  end

  @doc """
  Verifies and decodes a signed attrs token. Accepts tokens up to 30 days old.
  """
  def verify_attrs(token) do
    Phoenix.Token.verify(GlossiaWeb.Endpoint, "og-image", token, max_age: 30 * 86_400)
  end

  @doc """
  Returns the absolute URL to the static fallback logo.
  """
  def fallback_url do
    GlossiaWeb.Endpoint.url() <> "/images/logo-squared.jpg"
  end

  @doc """
  Fetches a cached OG image from S3, or generates and uploads one.

  Returns `{:ok, jpeg_bytes}` or `{:error, reason}`.
  """
  def fetch_or_generate(s3_path, attrs) do
    Tracer.with_span "glossia.og_image.fetch_or_generate" do
      Tracer.set_attributes([
        {"glossia.og_image.s3_path", to_string(s3_path)},
        {"glossia.og_image.category", to_string(attrs[:category] || attrs["category"] || "")}
      ])

      with {:ok, _} <- safe_s3_head(s3_path),
           {:ok, %{body: body}} <- Glossia.Storage.download(s3_path) do
        {:ok, body}
      else
        _ ->
          with {:ok, bytes} <- generate(attrs) do
            case Glossia.Storage.upload(s3_path, bytes, content_type: "image/jpeg") do
              {:ok, _} -> Logger.info("OG image cached to S3: #{s3_path}")
              {:error, reason} -> Logger.warning("OG image S3 upload failed: #{inspect(reason)}")
            end

            {:ok, bytes}
          end
      end
    end
  end

  defp safe_s3_head(path) do
    Glossia.Storage.head(path)
  rescue
    e ->
      Logger.debug("S3 HEAD check failed: #{inspect(e)}")
      {:error, :s3_unavailable}
  end

  @doc """
  Generates an OG image from the given attributes using ChromicPDF.

  Returns `{:ok, jpeg_bytes}` or `{:error, reason}`.
  """
  def generate(attrs) do
    Tracer.with_span "glossia.og_image.generate" do
      title = attrs[:title] || attrs["title"] || "Glossia"
      description = attrs[:description] || attrs["description"] || ""
      category = attrs[:category] || attrs["category"] || ""
      author_name = attrs[:author_name] || attrs["author_name"] || ""
      author_avatar = attrs[:author_avatar] || attrs["author_avatar"] || ""

      Tracer.set_attributes([
        {"glossia.og_image.category", to_string(category)}
      ])

      html =
        EEx.eval_file(template_path(),
          title: title,
          description: description,
          category: category,
          author_name: author_name,
          author_avatar: author_avatar
        )

      case ChromicPDF.capture_screenshot({:html, html},
             capture_screenshot: %{
               format: "jpeg",
               quality: 90,
               clip: %{x: 0, y: 0, width: 1200, height: 630, scale: 1}
             },
             full_page: true
           ) do
        {:ok, base64_data} ->
          {:ok, Base.decode64!(base64_data)}

        error ->
          Logger.error("OG image generation failed: #{inspect(error)}")
          error
      end
    end
  end

  defp enabled? do
    Application.get_env(:glossia, __MODULE__, [])[:enabled] != false
  end
end
