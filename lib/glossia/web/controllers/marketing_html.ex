defmodule Glossia.Web.MarketingHTML do
  use Glossia.Web, :app_html
  use Glossia.Web, :marketing_html

  embed_templates "marketing_html/app/*", suffix: "_app"
  embed_templates "marketing_html/*"

  def get_seo_metadata(:beta, _) do
    %{
      title: "Beta Testing",
      description:
        "Join the future of automation today! Register on our page to become a beta tester for Glossia, the groundbreaking technology set to revolutionize your workflow. Sign up and be the first to experience Glossia’s innovative capabilities."
    }
  end

  def get_seo_metadata(:blog, _) do
    %{
      title: "Blog",
      description:
        "Dive into the Glossia Blog, your go-to resource for insights on AI-powered translation, software localization, and innovative chat-based collaboration. Learn how Glossia revolutionizes language adaptability, fostering a global software community. Stay tuned for thought-provoking articles, tips, and more."
    }
  end

  def get_seo_metadata(:blog_post, %{post: %{title: title, description: description, tags: tags}}) do
    %{
      title: title,
      description: description,
      keywords: tags
    }
  end

  def get_seo_metadata(:beta_added, _) do
    %{
      title: "Successful Subscription to Glossia Beta Testing!",
      description:
        "Congratulations on your successful subscription to the Glossia Beta Testing! Your voyage into the future of automation begins soon. Stay tuned for launch details."
    }
  end

  def get_seo_metadata(:team, _) do
    %{
      title: "Our Team",
      description:
        "Meet the team of innovative minds behind Glossia, the leading AI-powered localization tool transforming how businesses communicate across borders. Our diverse team of experts, dedicated to improving global communication, is committed to making localization more efficient and accurate than ever."
    }
  end

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
