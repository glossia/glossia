// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/glossia"
import topbar from "../vendor/topbar"
import Noora from "noora"
import ModelPicker from "./model_picker"
import LocalizationPriorityMap from "./analytics_map"
import AnalyticsTraffic from "./analytics_traffic"

function initSentry() {
  const dsn = document.querySelector("meta[name='sentry-dsn']")?.getAttribute("content")
  if (!dsn || !window.Sentry) return

  window.Sentry.init({
    dsn,
    environment:
      document.querySelector("meta[name='sentry-environment']")?.getAttribute("content") || undefined,
    release: document.querySelector("meta[name='sentry-release']")?.getAttribute("content") || undefined,
  })
}

initSentry()

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...Noora.Hooks, ModelPicker, LocalizationPriorityMap, AnalyticsTraffic},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#6d3cc4"}, shadowColor: "rgba(0, 0, 0, .15)"})
window.addEventListener("phx:page-loading-start", info => {
  if(info.detail.kind === "initial" || info.detail.kind === "error") return
  topbar.show(500)
})
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Show a persistent topbar when the LiveView connection is lost
window.addEventListener("phx:disconnected", () => topbar.show(0))
window.addEventListener("phx:connected", () => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// Add copy buttons to all code blocks inside .prose
function initCodeCopyButtons() {
  const copyIcon = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>'
  const checkIcon = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>'

  document.querySelectorAll(".prose pre").forEach(pre => {
    if (pre.querySelector(".code-copy-btn")) return
    const btn = document.createElement("button")
    btn.className = "code-copy-btn"
    btn.setAttribute("type", "button")
    btn.setAttribute("aria-label", "Copy code")
    btn.innerHTML = copyIcon
    btn.addEventListener("click", () => {
      const code = pre.querySelector("code")
      const text = code ? code.textContent : pre.textContent
      navigator.clipboard.writeText(text).then(() => {
        btn.innerHTML = checkIcon
        btn.classList.add("copied")
        setTimeout(() => {
          btn.innerHTML = copyIcon
          btn.classList.remove("copied")
        }, 1500)
      })
    })
    pre.appendChild(btn)
  })
}

function initDocsLayout() {
  const layout = document.getElementById("docs-page-layout")
  if (!layout || layout.dataset.docsInitialized) return

  layout.dataset.docsInitialized = "true"
  initDocsPortals(layout)

  const body = document.body
  const sidebar = document.getElementById("docs-sidebar")
  const sidebarTriggers = document.querySelectorAll("[data-docs-sidebar-trigger]")
  const sidebarClose = document.querySelector("[data-docs-sidebar-close]")
  const toc = document.getElementById("docs-mobile-toc")
  const tocTrigger = document.querySelector("[data-docs-toc-trigger]")
  const searchDialog = document.getElementById("docs-search")
  const searchInput = document.querySelector("[data-docs-search-input]")
  const searchResults = document.getElementById("docs-search-results")

  const closeSidebar = () => {
    body.removeAttribute("data-docs-sidebar-open")
    sidebar?.removeAttribute("data-mobile-open")
    sidebarTriggers.forEach(trigger => trigger.setAttribute("aria-expanded", "false"))
  }

  const toggleSidebar = () => {
    const open = !body.hasAttribute("data-docs-sidebar-open")
    body.toggleAttribute("data-docs-sidebar-open", open)
    sidebar?.toggleAttribute("data-mobile-open", open)
    sidebarTriggers.forEach(trigger => trigger.setAttribute("aria-expanded", String(open)))
  }

  sidebarTriggers.forEach(trigger => trigger.addEventListener("click", toggleSidebar))
  sidebarClose?.addEventListener("click", closeSidebar)
  sidebar?.querySelectorAll("a").forEach(link => link.addEventListener("click", closeSidebar))

  const closeToc = () => {
    toc?.setAttribute("data-state", "closed")
    tocTrigger?.setAttribute("aria-expanded", "false")
  }

  tocTrigger?.addEventListener("click", () => {
    const open = toc?.getAttribute("data-state") !== "open"
    toc?.setAttribute("data-state", open ? "open" : "closed")
    tocTrigger.setAttribute("aria-expanded", String(open))
  })
  toc?.querySelectorAll("[data-docs-toc-link]").forEach(link => link.addEventListener("click", closeToc))

  const renderSearchResults = (results, query) => {
    if (!searchResults) return
    searchResults.replaceChildren()

    if (!query || query.trim().length < 2) {
      const empty = document.createElement("p")
      empty.dataset.part = "search-empty"
      empty.textContent = searchDialog?.dataset.searchPrompt
      searchResults.appendChild(empty)
      return
    }

    if (results.length === 0) {
      const empty = document.createElement("p")
      empty.dataset.part = "search-empty"
      empty.textContent = searchDialog?.dataset.searchEmpty
      searchResults.appendChild(empty)
      return
    }

    results.forEach(page => {
      const result = document.createElement("a")
      result.href = page.url
      result.dataset.part = "search-result"

      const title = document.createElement("strong")
      title.textContent = page.title
      const summary = document.createElement("span")
      summary.textContent = page.summary

      result.append(title, summary)
      searchResults.appendChild(result)
    })
  }

  let searchTimer
  let searchController

  const searchDocumentation = async query => {
    const normalized = query.trim()

    if (normalized.length < 2) {
      renderSearchResults([], normalized)
      return
    }

    searchController?.abort()
    searchController = new AbortController()

    const endpoint = new URL("/docs/search.json", window.location.origin)
    endpoint.searchParams.set("locale", document.documentElement.lang || "en")
    endpoint.searchParams.set("q", normalized)

    try {
      const response = await fetch(endpoint, {signal: searchController.signal})
      const payload = response.ok ? await response.json() : {results: []}

      if (searchInput?.value.trim() === normalized) {
        renderSearchResults(payload.results || [], normalized)
      }
    } catch (error) {
      if (error.name !== "AbortError") renderSearchResults([], normalized)
    }
  }

  const openSearch = event => {
    event?.preventDefault()
    if (!searchDialog?.open) searchDialog?.showModal()
    searchInput?.focus()

    searchDocumentation(searchInput?.value || "")
  }

  document.querySelectorAll("[data-docs-search-trigger]").forEach(trigger => {
    trigger.addEventListener("focus", openSearch)
    trigger.addEventListener("click", openSearch)
  })

  searchInput?.addEventListener("input", event => {
    window.clearTimeout(searchTimer)
    searchTimer = window.setTimeout(() => searchDocumentation(event.target.value), 200)
  })
  searchDialog?.addEventListener("close", () => {
    searchController?.abort()
    window.clearTimeout(searchTimer)
    if (searchInput) searchInput.value = ""
  })

  document.addEventListener("keydown", event => {
    if ((event.metaKey || event.ctrlKey) && event.key.toLocaleLowerCase() === "k") {
      openSearch(event)
    }

    if (event.key === "Escape") {
      closeSidebar()
      closeToc()
    }
  })

  if (!document.documentElement.dataset.docsCopyPageInitialized) {
    document.documentElement.dataset.docsCopyPageInitialized = "true"

    document.addEventListener("click", async event => {
      const mainButton = event.target.closest("[data-docs-copy-page]")
      const menuItem = event.target.closest("[data-docs-copy-markdown]")
      if (!mainButton && !menuItem) return

      if (menuItem) event.preventDefault()

      const markdown = document.getElementById("docs-page-markdown")?.value
      if (!markdown || !navigator.clipboard) return

      try {
        await navigator.clipboard.writeText(markdown)
      } catch (_error) {
        return
      }

      document.querySelectorAll("[data-docs-copy-page]").forEach(button => {
        const label = button.querySelector('[data-part="label"]')
        if (!label) return

        window.clearTimeout(button.docsCopyTimeout)
        label.textContent = button.dataset.copiedLabel || "Copied"
        button.docsCopyTimeout = window.setTimeout(() => {
          label.textContent = button.dataset.defaultLabel || "Copy page"
        }, 3000)
      })
    })
  }

  const tocLinks = document.querySelectorAll("#docs-toc [data-docs-toc-link]")
  const headings = Array.from(tocLinks)
    .map(link => document.getElementById(link.getAttribute("href")?.slice(1)))
    .filter(Boolean)

  if (headings.length && "IntersectionObserver" in window) {
    const observer = new IntersectionObserver(entries => {
      entries.filter(entry => entry.isIntersecting).forEach(entry => {
        tocLinks.forEach(link => link.removeAttribute("data-active"))
        document.querySelector(`#docs-toc [href="#${CSS.escape(entry.target.id)}"]`)?.setAttribute("data-active", "")
      })
    }, {rootMargin: "0px 0px -80% 0px"})

    headings.forEach(heading => observer.observe(heading))
  }
}

// Documentation pages are controller-rendered. Move Noora portal content into
// its component target before LiveView mounts the Noora dropdown hook.
function initDocsPortals(layout) {
  layout.querySelectorAll("template[data-phx-portal]").forEach(portal => {
    const target = document.querySelector(portal.dataset.phxPortal)
    if (!target || target.childElementCount) return

    target.replaceChildren(portal.content.cloneNode(true))
    portal.remove()
  })
}

// Run on initial page load and on LiveView page navigations
initCodeCopyButtons()
initDocsLayout()
window.addEventListener("phx:page-loading-stop", () => {
  setTimeout(() => {
    initCodeCopyButtons()
    initDocsLayout()
  }, 100)
})

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    const resetKeyDown = () => keyDown = null

    window.addEventListener("keydown", e => keyDown = e.key?.toLowerCase())
    window.addEventListener("keyup", _e => resetKeyDown())
    window.addEventListener("blur", () => resetKeyDown())
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState !== "visible") resetKeyDown()
    })

    window.addEventListener("click", e => {
      if (!e.altKey) return
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
