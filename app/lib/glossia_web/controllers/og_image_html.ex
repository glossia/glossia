defmodule GlossiaWeb.OgImageHTML do
  use GlossiaWeb, :html
  import Noora.Badge

  embed_templates "og_image_html/*"

  def document(attrs, project_logo) do
    image(%{
      title: attrs[:title] || "Glossia",
      description: attrs[:description] || attrs[:summary] || "",
      category: attrs[:category] || "Language, in good company",
      logo: project_logo,
      brand: asset("images/logo-rounded.png", "image/png"),
      font: asset("fonts/inter.woff2", "font/woff2"),
      serif_font: asset("fonts/source-serif-4.woff2", "font/woff2"),
      styles: File.read!(static_path("assets/styles.css")),
      noora: File.read!(static_path("assets/noora.css"))
    })
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp static_path(path), do: Path.join(:code.priv_dir(:glossia), "static/" <> path)

  defp asset(path, type) do
    "data:#{type};base64,#{Base.encode64(File.read!(static_path(path)))}"
  end
end
