defmodule Glossia.OgImage do
  @moduledoc """
  Lazy daily content-addressed social images. Only signed current-day content
  can start a browser. Yesterday's stored images remain readable.
  """
  use GlossiaWeb, :verified_routes

  alias Glossia.OgImage.Cache
  alias Glossia.Storage

  @design_files Path.wildcard("assets/css/**/*.css") ++
                  Path.wildcard("lib/glossia_web/controllers/og_image_html/*") ++
                  [
                    "lib/glossia_web/controllers/og_image_html.ex",
                    "priv/static/assets/styles.css",
                    "priv/static/fonts/inter.woff2",
                    "priv/static/fonts/source-serif-4.woff2",
                    "priv/static/images/logo-rounded.png",
                    "mix.lock"
                  ]
  for file <- @design_files do
    @external_resource file
  end

  @design :crypto.hash(:sha256, Enum.map(@design_files, &File.read!/1))

  def hash(attrs, day \\ Date.utc_today()) do
    {Enum.sort(attrs), Date.to_iso8601(day), @design}
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
  end

  def marketing_url(attrs) do
    image_url(attrs, fn filename, token ->
      ~p"/og/marketing/#{attrs[:category] || "page"}/#{filename}?#{[d: token]}"
    end)
  end

  def account_url(handle, attrs) do
    image_url(attrs, fn filename, token ->
      ~p"/og/app/#{handle}/#{filename}?#{[d: token]}"
    end)
  end

  def project_url(handle, project, attrs) do
    image_url(attrs, fn filename, token ->
      ~p"/og/app/#{handle}/#{project}/#{filename}?#{[d: token]}"
    end)
  end

  defp image_url(attrs, path) do
    if enabled?() do
      day = Date.utc_today()
      absolute_url(path.(hash(attrs, day) <> ".jpg", sign_attrs(attrs, day)))
    end
  end

  def sign_attrs(attrs, day \\ Date.utc_today()) do
    Phoenix.Token.sign(GlossiaWeb.Endpoint, "og-image-v2", %{attrs: attrs, day: day},
      signed_at: day |> DateTime.new!(~T[00:00:00]) |> DateTime.to_unix()
    )
  end

  def verify_attrs(token) when is_binary(token) and byte_size(token) <= 8192 do
    Phoenix.Token.verify(GlossiaWeb.Endpoint, "og-image-v2", token, max_age: 2 * 86_400)
  end

  def verify_attrs(_), do: {:error, :invalid_token}
  def fallback_url, do: absolute_url(~p"/images/logo-squared.jpg")
  defp absolute_url(path), do: GlossiaWeb.Endpoint.url() |> URI.merge(path) |> URI.to_string()
  def enabled?, do: Application.get_env(:glossia, __MODULE__, [])[:enabled] != false

  def fetch_or_generate(key, attrs, day \\ Date.utc_today(), cache \\ Cache) do
    Cache.fetch(key, fn -> resolve(key, attrs, day) end, cache)
  end

  defp resolve(key, attrs, day) do
    case Storage.download(key) do
      {:ok, %{body: bytes}} -> {:ok, bytes}
      {:error, {:http_error, 404, _}} -> generate_missing(key, attrs, day)
      {:error, _} = error -> error
    end
  rescue
    _ -> {:error, :storage_unavailable}
  end

  defp generate_missing(key, attrs, day) do
    if day == Date.utc_today() and enabled?() do
      # Nonblocking database locks coalesce misses across application replicas.
      <<lock::signed-64, _::binary>> = :crypto.hash(:sha256, key)

      case Glossia.Repo.transaction(
             fn ->
               case Glossia.Repo.query!("SELECT pg_try_advisory_xact_lock($1)", [lock]).rows do
                 [[true]] -> generate_locked(key, attrs)
                 [[false]] -> {:error, :busy}
               end
             end,
             timeout: 25_000
           ) do
        {:ok, result} -> result
        {:error, _} = error -> error
      end
    else
      {:error, :expired}
    end
  end

  defp generate_locked(key, attrs) do
    # Another replica may have uploaded between the first read and this lock.
    case Storage.download(key) do
      {:ok, %{body: bytes}} -> {:ok, bytes}
      {:error, {:http_error, 404, _}} -> render_and_store(key, attrs)
      {:error, _} = error -> error
    end
  end

  defp render_and_store(key, attrs) do
    case Glossia.RateLimiter.hit("og-image:renders", :timer.minutes(1), 12) do
      {:allow, _} ->
        with {:ok, bytes} <- generate(attrs),
             {:ok, _} <- Storage.upload(key, bytes, content_type: "image/jpeg") do
          {:ok, bytes}
        end

      {:deny, _} ->
        {:error, :busy}
    end
  end

  def generate(attrs) do
    with {:ok, logo} <- project_logo(attrs[:project_avatar]) do
      html = GlossiaWeb.OgImageHTML.document(attrs, logo)

      task =
        Task.Supervisor.async_nolink(Glossia.OgImage.Tasks, fn ->
          Carta.render(Glossia.OgImage.BrowserPool, html, width: 1200, height: 630, quality: 90)
        end)

      case Task.yield(task, 15_000) || Task.shutdown(task, :brutal_kill) do
        {:ok, result} -> result
        _ -> {:error, :render_timeout}
      end
    end
  rescue
    _ -> {:error, :render_failed}
  catch
    :exit, _ -> {:error, :render_timeout}
  end

  defp project_logo(nil), do: {:ok, nil}
  defp project_logo(""), do: {:ok, nil}

  defp project_logo("avatars/" <> _ = key) do
    with {:ok, %{body: bytes}} when byte_size(bytes) <= 5_000_000 <- Storage.download(key),
         type when type in ["image/png", "image/jpeg", "image/webp", "image/gif"] <-
           MIME.from_path(key) do
      {:ok, "data:#{type};base64,#{Base.encode64(bytes)}"}
    else
      _ -> {:error, :logo_unavailable}
    end
  end

  defp project_logo(_), do: {:error, :invalid_logo}
end
