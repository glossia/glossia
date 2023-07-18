defmodule GlossiaWeb.MarketingComponents do
  use GlossiaWeb, :verified_routes
  use GlossiaWeb.SEO

  @moduledoc """
  It provides marketing components
  """

  use Phoenix.Component

  def navigation(assigns) do
    ~H"""
    <div class="mx-auto w-full bg-lila-500 2xl:border-2 justify-center sticky top-0 z-20 2xl:max-w-7xl border-y-2 border-black">
      <div
        class="mx-auto w-full flex flex-col lg:flex-row py-6 md:py-0 lg:items-center lg:justify-between 2xl:max-w-7xl px-8 md:px-0"
        x-data="{ open: false }"
      >
        <div class="text-black items-center flex justify-between flex-row">
          <a
            class="text-black items-center font-bold gap-3 inline-flex text-2xl tracking-tighter md:hidden"
            href="/"
          >
            <span>GLOSSIA.</span>
          </a>
          <button
            class="focus:outline-none focus:shadow-outline md:hidden ml-auto border-2 border-black bg-red-500"
            @click="open = !open"
          >
            <svg class="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                x-bind:class="{'hidden': open, 'inline-flex': !open }"
                class="inline-flex"
                d="M4 6h16M4 12h16M4 18h16"
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
              >
              </path>
              <path
                x-bind:class="{'hidden': !open, 'inline-flex': open }"
                class="hidden"
                d="M6 18L18 6M6 6l12 12"
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
              >
              </path>
            </svg>
          </button>
        </div>
        <nav
          x-bind:class="{'flex': open, 'hidden': !open}"
          class="flex-col items-center flex-grow hidden md:flex md:flex-row md:justify-start md:mt-0 lg:p-0 py-2 md:py-0 md:px-0 md:pb-0 px-5"
        >
          <a
            class="text-black duration-1000 text-lg ease-in-out focus:outline-none focus:shadow-none focus:text-orange/90 hover:text-lila-900 md:my-0 px-4 py-2 transform transition md:ml-8 lg:ml-16 2xl:ml-0"
            href="/"
          >
            Home
          </a>

          <a
            class="text-black duration-1000 text-lg ease-in-out focus:outline-none focus:shadow-none focus:text-orange/90 hover:text-lila-900 md:my-0 px-4 py-2 transform transition"
            href={~p"/blog"}
          >
            Blog
          </a>
          <a
            class="text-black duration-1000 text-lg ease-in-out focus:outline-none focus:shadow-none focus:text-orange/90 hover:text-lila-900 md:my-0 px-4 py-2 transform transition"
            href="https://discord.gg/zqZxSBXKf8"
          >
            Discord
          </a>

          <a
            class="text-lila-500 md:ml-auto text-lg bg-black border-l-2 border-black duration-500 ease-in-out focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 hover:bg-lila-900 hover:text-lila-500 inline-flex items-center justify-center px-6 text-center transform transition py-2 md:py-8"
            href={~p"/beta"}
          >
            <span>Join the list for beta testers</span>
          </a>
        </nav>
      </div>
    </div>
    """
  end

  def footer(assigns) do
    ~H"""
    <footer class="bg-white border-t-2 border-black">
      <div class="p-8 lg:p-20 2xl:px-0 2xl:max-w-7xl mx-auto">
        <div class="h-full space-y-12">
          <div>
            <div class="w-full justify-between lg:inline-flex lg:items-start h-full gap-3">
              <div class="flex flex-col">
                <p class="font-bold text-6xl">GLOSSIA</p>

                <div>
                  <h3 class="text-sm text-black mt-12">
                    Please provide us with your email, and you will be one of the
                    first to try the tool.
                  </h3>
                  <a
                    class="mt-4 items-center w-full border-black flex border-2 bg-black focus:outline-none focus:ring-2 focus:ring-black focus:ring-offset-2 font-medium hover:bg-lila-500 hover:text-black justify-center px-5 py-3 rounded-xl text-base text-white"
                    href="/beta"
                  >
                    <svg
                      class="h-6 mr-3 w-6"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <path
                        d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      >
                      </path>
                    </svg>
                    Join the list for beta testers
                  </a>
                </div>
              </div>
              <div>
                <div class="md:gap-8 grid mt-12 lg:mt-0">
                  <div>
                    <ul class="space-y-2" role="list">
                      <li>
                        <a
                          class="text-lg text-black hover:text-lila-400"
                          href="https://discord.gg/zqZxSBXKf8"
                        >
                          Discord
                        </a>
                      </li>
                      <li>
                        <a
                          class="text-lg text-black hover:text-lila-400"
                          href="https://twitter.com/glossiaai"
                        >
                          @glossiaai
                        </a>
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div>
            <div class="w-full justify-between lg:inline-flex lg:items-center lg:space-y-0 space-y-3">
              <div>
                <p class="text-black text-sm">
                  María José Salmerón -
                  <span class="text-grayer">© Copyright 2023 . All rights reserved.</span>
                </p>
              </div>
              <div>
                <div class="flex space-x-6 md:order-2">
                  <!-- <a href="#" class="text-black hover:text-lila-900">
                <span class="sr-only">Instagram</span>
                <svg
                  class="h-4 w-4"
                  fill="currentColor"
                  viewBox="0 0 24 24"
                  aria-hidden="true">
                  <path
                    fill-rule="evenodd"
                    d="M12.315 2c2.43 0 2.784.013 3.808.06 1.064.049 1.791.218 2.427.465a4.902 4.902 0 011.772 1.153 4.902 4.902 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.466.399.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM12 6.865a5.135 5.135 0 110 10.27 5.135 5.135 0 010-10.27zm0 1.802a3.333 3.333 0 100 6.666 3.333 3.333 0 000-6.666zm5.338-3.205a1.2 1.2 0 110 2.4 1.2 1.2 0 010-2.4z"
                    clip-rule="evenodd"></path>
                </svg>
              </a> -->
                  <a href="https://twitter.com/glossiaai" class="text-black hover:text-lila-900">
                    <span class="sr-only">Twitter</span>
                    <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84">
                      </path>
                    </svg>
                  </a>

                  <a href="https://github.com/glossia" class="text-black hover:text-lila-900">
                    <span class="sr-only">GitHub</span>
                    <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path
                        fill-rule="evenodd"
                        d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
                        clip-rule="evenodd"
                      >
                      </path>
                    </svg>
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </footer>
    """
  end

  def cta(assigns) do
    ~H"""
    <section class="relative flex items-center w-full border-y-2 border-black bg-green-400 2xl:max-w-7xl mx-auto mb-20">
      <div class="items-center w-full mx-auto 2xl:max-w-7xl p-8 lg:p-20 2xl:px-0 2xl:border-x-2 border-black">
        <div class="items-center gap-12 h-full">
          <div class="text-center max-w-3xl mx-auto">
            <p class="text-3xl font-display lg:text-5xl text-black">
              Hop into Localization
            </p>
            <p class="max-w-2xl mx-auto mt-4 xl:text-2xl tracking-tight text-black">
              Eager for Glossia's big debut, the new kid on the web frameworks block? Leave your email, and we'll ping you when it's ready to take your projects global!
            </p>
            <div class="justify-center mt-12 w-full mx-auto">
              <a
                class="mx-auto items-center focus:outline-none focus:ring-2 focus:ring-offset-2 justify-center font-medium bg-black border border-transparent flex focus:ring-black hover:bg-lila-500 hover:text-black px-5 py-3 rounded-xl text-base text-white"
                href="/beta"
              >
                <svg
                  class="h-6 mr-3 w-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                  </path>
                </svg>
                Join the list for beta testers
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  def meta(assigns) do
    ~H"""
    <title><%= get_seo_metadata(@conn)[:title] %></title>
    <meta property="article:published_time" content="2022-09-07T00:00:00+00:00" />
    <meta name="description" content={get_seo_metadata(@conn)[:description]} />
    <meta name="author" content={Application.fetch_env!(:glossia, :seo_metadata).author} />
    <!-- Open graph -->
    <meta property="og:title" content={get_seo_metadata(@conn)[:title]} />
    <meta property="og:description" content={get_seo_metadata(@conn)[:description]} />
    <meta property="og:type" content="article" />
    <meta property="og:site_name" content="Pedro Piñera" />
    <meta property="og:url" content={Phoenix.Controller.current_url(@conn)} />
    <meta property="og:image" content={image(@conn)} />
    <!-- Twitter -->
    <meta name="twitter:card" content="summary" />
    <meta name="twitter:title" content={get_seo_metadata(@conn)[:title]} />
    <meta name="twitter:description" content={get_seo_metadata(@conn)[:description]} />
    <meta name="twitter:image" content={image(@conn)} />
    <meta
      name="twitter:site"
      content={Application.fetch_env!(:glossia, :seo_metadata).twitter_handle}
    />
    <meta property="twitter:domain" content={Application.fetch_env!(:glossia, :seo_metadata).domain} />
    <meta
      property="twitter:url"
      content={Application.fetch_env!(:glossia, :seo_metadata).base_url |> URI.to_string()}
    />
    <!-- Favicon -->
    <link rel="shortcut icon" href={static_asset_url("/favicons/favicon.ico")} />
    <link
      rel="apple-touch-icon"
      sizes="180x180"
      href={static_asset_url("/favicon/apple-touch-icon.png")}
    />
    <link
      rel="icon"
      type="image/png"
      sizes="32x32"
      href={static_asset_url("/favicon/favicon-32x32.png")}
    />
    <link
      rel="icon"
      type="image/png"
      sizes="16x16"
      href={static_asset_url("/favicon/favicon-16x16.png")}
    />
    <link rel="manifest" href={static_asset_url("/favicon/site.webmanifest")} />
    <meta name="msapplication-TileColor" content="#da532c" />
    <meta name="theme-color" content="#ffffff" />
    """
  end

  defp image(_conn) do
    static_asset_url("/images/logo.jpg")
  end

  defp static_asset_url(path) do
    Application.fetch_env!(:glossia, :seo_metadata).base_url |> URI.merge(path) |> URI.to_string()
  end
end
