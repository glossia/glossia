defmodule GlossiaWeb.MarketingComponents do
  @moduledoc """
  It provides marketing components
  """
  use Boundary, deps: [GlossiaWeb.Gettext]

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import GlossiaWeb.Gettext

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
                class="inline-flex"
                d="M4 6h16M4 12h16M4 18h16"
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
              >
              </path>
              <path
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
        <nav class="flex-col items-center flex-grow hidden md:flex md:flex-row md:justify-start md:mt-0 lg:p-0 py-2 md:py-0 md:px-0 md:pb-0 px-5">
          <a
            class="text-black duration-1000 text-lg ease-in-out focus:outline-none focus:shadow-none focus:text-orange/90 hover:text-lila-900 md:my-0 px-4 py-2 transform transition md:ml-8 lg:ml-16 2xl:ml-0"
            href="/"
          >
            Home
          </a>

          <a
            class="text-black duration-1000 text-lg ease-in-out focus:outline-none focus:shadow-none focus:text-orange/90 hover:text-lila-900 md:my-0 px-4 py-2 transform transition"
            href="/blog"
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
            href="/beta"
          >
            <span>Join the list for beta testers</span>
          </a>
        </nav>
      </div>
    </div>
    """
  end
end
