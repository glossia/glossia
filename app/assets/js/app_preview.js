// Only bounded input and JPEG frames cross the preview boundary, never app HTML.
const AppPreview = {
  mounted() {
    this.expanded = false
    this.lastActivity = Date.now()
    this.activity = () => { this.lastActivity = Date.now() }
    this.heartbeat = () => {
      const doc = this.el.ownerDocument
      if (doc.visibilityState === "visible" && doc.hasFocus() &&
          Date.now() - this.lastActivity < 60000 && this.el.querySelector("#editor-stop-preview"))
        this.pushEvent("preview_heartbeat", {})
    }
    this.heartbeatTimer = setInterval(this.heartbeat, 30000)
    for (const event of ["pointerdown", "keydown", "wheel", "input"])
      this.el.ownerDocument.addEventListener(event, this.activity, {passive: true})
    this.toggle = event => {
      if (event.target.closest("[data-preview-toggle]")) {
        this.expanded = !this.expanded
        this.applySize()
      } else if (event.target.id === "editor-app-frame") {
        this.sendInput(this.pointerInput(event, {type: "click"}))
      }
    }
    this.wheel = event => {
      if (event.target.id !== "editor-app-frame" || event.ctrlKey) return
      event.preventDefault()
      const scroll = this.pointerInput(event, {type: "scroll"})
      if (!scroll) return
      const unit = event.deltaMode === 1 ? 16 : event.deltaMode === 2 ? 800 : 1
      const previous = this.scroll?.revision === scroll.revision ? this.scroll.input : null
      scroll.input.delta_x = Math.max(-1200, Math.min(1200, Math.round((previous?.delta_x || 0) + event.deltaX * unit)))
      scroll.input.delta_y = Math.max(-1200, Math.min(1200, Math.round((previous?.delta_y || 0) + event.deltaY * unit)))
      this.scroll = scroll
      if (!this.scrollTimer) this.scrollTimer = setTimeout(() => {
        const scroll = this.scroll
        this.scroll = null
        this.scrollTimer = null
        this.sendInput(scroll)
      }, 100)
    }
    this.key = event => {
      if (event.key === "Escape" && this.expanded) {
        this.expanded = false
        this.applySize()
        this.el.querySelector("[data-preview-toggle]").focus()
      }
      if (event.target.id !== "editor-app-frame" || !this.ready()) return
      const delta = {ArrowDown: 160, ArrowUp: -160, PageDown: 640, PageUp: -640}[event.key]
      if (!delta) return
      event.preventDefault()
      this.sendInput({revision: Number(event.target.dataset.revision),
        input: {type: "scroll", x: 600, y: 400, delta_x: 0, delta_y: delta}})
    }
    this.el.addEventListener("click", this.toggle)
    this.el.addEventListener("wheel", this.wheel, {passive: false})
    this.el.addEventListener("keydown", this.key)
    this.applySize()
  },
  updated() { this.applySize() },
  applySize() {
    this.el.dataset.expanded = String(this.expanded)
    const button = this.el.querySelector("[data-preview-toggle]")
    button.setAttribute("aria-expanded", String(this.expanded))
    button.querySelector("span").textContent = this.expanded
      ? this.el.dataset.collapseLabel : this.el.dataset.expandLabel
  },
  ready() {
    return this.el.querySelector("#editor-app-frame")?.dataset.status === "ready"
  },
  pointerInput(event, input) {
    if (!this.ready()) return
    const frame = this.el.querySelector("#editor-app-frame")
    const rect = frame.getBoundingClientRect()
    if (!rect.width || !rect.height) return
    const x = Math.floor((event.clientX - rect.left) / rect.width * 1200)
    const y = Math.floor((event.clientY - rect.top) / rect.height * 800)
    if (x < 0 || x >= 1200 || y < 0 || y >= 800) return
    return {revision: Number(frame.dataset.revision), input: {...input, x, y}}
  },
  sendInput(payload) {
    if (!payload || !this.ready() || payload.revision !== Number(this.el.querySelector("#editor-app-frame").dataset.revision)) return
    this.pushEvent("preview_input", payload)
  },
  destroyed() {
    clearTimeout(this.scrollTimer)
    clearInterval(this.heartbeatTimer)
    for (const event of ["pointerdown", "keydown", "wheel", "input"])
      this.el.ownerDocument.removeEventListener(event, this.activity)
    this.el.removeEventListener("click", this.toggle)
    this.el.removeEventListener("wheel", this.wheel)
    this.el.removeEventListener("keydown", this.key)
  },
}

export default AppPreview
