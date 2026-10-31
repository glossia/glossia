// Only bounded input and JPEG frames cross the preview boundary, never app HTML.
const AppPreview = {
  mounted() {
    this.expanded = false
    this.toggle = event => {
      if (event.target.closest("[data-preview-toggle]")) {
        this.expanded = !this.expanded
        this.applySize()
      } else if (event.target.id === "editor-app-frame") {
        this.sendInput(event, {type: "click"})
      }
    }
    this.wheel = event => {
      if (event.target.id !== "editor-app-frame" || event.ctrlKey) return
      event.preventDefault()
      if (!this.ready()) return
      const unit = event.deltaMode === 1 ? 16 : event.deltaMode === 2 ? 800 : 1
      this.scroll = {
        event,
        revision: this.el.querySelector("#editor-app-frame").dataset.revision,
        x: Math.max(-1200, Math.min(1200, Math.round((this.scroll?.x || 0) + event.deltaX * unit))),
        y: Math.max(-1200, Math.min(1200, Math.round((this.scroll?.y || 0) + event.deltaY * unit))),
      }
      if (!this.scrollTimer) this.scrollTimer = setTimeout(() => {
        const scroll = this.scroll
        this.scroll = null
        this.scrollTimer = null
        if (scroll.revision === this.el.querySelector("#editor-app-frame")?.dataset.revision)
          this.sendInput(scroll.event, {type: "scroll", delta_x: scroll.x, delta_y: scroll.y})
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
      const rect = event.target.getBoundingClientRect()
      this.sendInput({clientX: rect.x + rect.width / 2, clientY: rect.y + rect.height / 2},
        {type: "scroll", delta_x: 0, delta_y: delta})
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
  sendInput(event, input) {
    if (!this.ready()) return
    const frame = this.el.querySelector("#editor-app-frame")
    const rect = frame.getBoundingClientRect()
    if (!rect.width || !rect.height) return
    const x = Math.floor((event.clientX - rect.left) / rect.width * 1200)
    const y = Math.floor((event.clientY - rect.top) / rect.height * 800)
    if (x < 0 || x >= 1200 || y < 0 || y >= 800) return
    this.pushEvent("preview_input", {revision: Number(frame.dataset.revision), input: {...input, x, y}})
  },
  destroyed() {
    clearTimeout(this.scrollTimer)
    this.el.removeEventListener("click", this.toggle)
    this.el.removeEventListener("wheel", this.wheel)
    this.el.removeEventListener("keydown", this.key)
  },
}

export default AppPreview
