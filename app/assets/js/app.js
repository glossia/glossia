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
  hooks: {...colocatedHooks},
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

// Run on initial page load and on LiveView page navigations
initCodeCopyButtons()
window.addEventListener("phx:page-loading-stop", () => {
  setTimeout(initCodeCopyButtons, 100)
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
