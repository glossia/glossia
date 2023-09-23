defmodule Glossia.Features.Cloud.Marketing.Web.Controllers.MarketingHTML do
  use Glossia.Features.Cloud.Marketing.Web.Helpers, :html

  embed_templates "marketing_html/app/*", suffix: "_app"
  embed_templates "marketing_html/*"

  def frameworks do
    [
      %{image: "rails.svg", url: "https://rubyonrails.org", alt: "The Ruby on Rails framework"},
      %{image: "remix.png", url: "https://remix.run", alt: "The Remix framework"},
      %{image: "nuxt.svg", url: "https://nuxt.com", alt: "The NuxtJS framework"},
      %{image: "redwood.svg", url: "https://redwoodjs.com", alt: "The Redwood framework"},
      %{image: "fresh.svg", url: "https://fresh.deno.dev", alt: "The Fresh framework"},
      %{image: "next.svg", url: "https://nextjs.org", alt: "The NextJS framework"},
      %{
        image: "phoenix.svg",
        url: "https://www.phoenixframework.org",
        alt: "The Phoenix framework"
      },
      %{image: "astro.svg", url: "https://astro.build", alt: "The Astro framework"},
      %{image: "laravel.svg", url: "https://laravel.com", alt: "The Laravel framework"}
    ]
  end
end
