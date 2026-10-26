// Keep unsent text across reconnects and reloads, scoped to actor and thread.
// No source history or approval message ID is stored in the browser.
export default {
  mounted() {
    this.textarea = this.el.querySelector("textarea")
    this.scope = this.el.querySelector('[name="resolution[context_scope]"]')
    this.key = this.el.dataset.draftKey
    this.persist = () => {
      try {
        sessionStorage.setItem(this.key, JSON.stringify({
          text: this.textarea.value,
          scope: this.scope?.value,
        }))
      } catch (_) { /* Storage can be disabled; the LiveView still keeps text. */ }
    }
    try {
      const saved = JSON.parse(sessionStorage.getItem(this.key) || "null")
      if (saved && typeof saved.text === "string") {
        this.textarea.value = saved.text
        if (this.scope && ["locale", "project"].includes(saved.scope)) {
          this.scope.value = saved.scope
        }
        // Hooks mount before LiveView's form listeners are guaranteed ready.
        // Restore server assigns explicitly as well as the visible field, so
        // the scope label, character count, and closed-goal recovery agree.
        if (this.scope) {
          this.pushEvent("guidance", {resolution: {
            guidance: saved.text,
            context_scope: this.scope.value,
          }})
        } else {
          this.pushEvent("draft", {message: {content: saved.text}})
        }
      }
    } catch (_) { /* An unavailable or obsolete draft must not break the chat. */ }
    this.el.addEventListener("input", this.persist)
    this.handleEvent("toki-draft-saved", ({form}) => {
      if (form !== this.el.id) return
      this.textarea.value = ""
      try { sessionStorage.removeItem(this.key) } catch (_) {}
    })
  },
  updated() {
    // Scope changes are server-rendered by the Noora dropdown, not text input.
    this.scope = this.el.querySelector('[name="resolution[context_scope]"]')
    if (this.scope) this.persist()
  },
  destroyed() {
    this.el.removeEventListener("input", this.persist)
  },
}
