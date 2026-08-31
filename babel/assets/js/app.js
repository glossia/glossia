import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import Noora from "noora"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const OrganizationVisuals = {
  mounted() {
    this.sync()
  },
  updated() {
    this.sync()
  },
  destroyed() {
    document.querySelector("#page-favicon").setAttribute("href", this.el.dataset.defaultFaviconHref)
  },
  sync() {
    const favicon = document.querySelector("#page-favicon")
    favicon.setAttribute("href", this.el.dataset.faviconHref || this.el.dataset.defaultFaviconHref)

    this.el.querySelectorAll(".noora-avatar[data-src]").forEach((avatar) => {
      const image = avatar.querySelector("[data-part='image']")
      const fallback = avatar.querySelector("[data-part='fallback']")

      if (!image) return

      const setStatus = (loaded) => {
        image.dataset.state = loaded ? "visible" : "hidden"
        if (fallback) fallback.dataset.state = loaded ? "hidden" : "visible"
      }

      if (image.complete) {
        setStatus(image.naturalWidth > 0)
      } else {
        image.addEventListener("load", () => setStatus(true), {once: true})
        image.addEventListener("error", () => setStatus(false), {once: true})
      }
    })
  },
}

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {...Noora.Hooks, OrganizationVisuals},
})

liveSocket.connect()
window.liveSocket = liveSocket
