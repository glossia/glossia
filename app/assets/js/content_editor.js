import {Editor} from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import {Markdown} from "@tiptap/markdown"
import Image from "@tiptap/extension-image"
import {TableKit} from "@tiptap/extension-table"
import TaskList from "@tiptap/extension-task-list"
import TaskItem from "@tiptap/extension-task-item"

const ContentEditor = {
  mounted() {
    this.bodyInput = this.el.querySelector("input[name='values[body]']")
    if (this.bodyInput) this.mountVisualEditor()
    this.beforeUnload = event => {
      if (this.unsaved()) {
        event.preventDefault()
        event.returnValue = ""
      }
    }
    this.beforeNavigate = event => {
      const link = event.target.closest("a[href]")
      if (!this.unsaved() || !link || event.defaultPrevented ||
          event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey ||
          link.target === "_blank" || link.hasAttribute("download") || link.hasAttribute("data-confirm") ||
          link.getAttribute("href").startsWith("#")) return
      if (!window.confirm(this.el.dataset.leaveConfirm)) {
        event.preventDefault()
        event.stopImmediatePropagation()
      }
    }
    this.format = event => {
      const button = event.target.closest("button[data-format]")
      if (!button || !this.rich?.isEditable) return
      event.preventDefault()
      const command = button.dataset.format
      const chain = this.rich.chain().focus()
      const actions = {
        heading: () => chain.toggleHeading({level: 2}).run(),
        paragraph: () => chain.setParagraph().run(),
        bold: () => chain.toggleBold().run(), italic: () => chain.toggleItalic().run(),
        list: () => chain.toggleBulletList().run(), ordered: () => chain.toggleOrderedList().run(),
        quote: () => chain.toggleBlockquote().run(), undo: () => chain.undo().run(), redo: () => chain.redo().run(),
        link: () => {
          const panel = this.el.querySelector("[data-part='link-controls']")
          panel.hidden = !panel.hidden
          const input = panel.querySelector("input")
          input.value = this.rich.getAttributes("link").href || ""
          input.setCustomValidity("")
          if (!panel.hidden) input.focus()
          else input.value = ""
        },
        apply_link: () => {
          const panel = this.el.querySelector("[data-part='link-controls']")
          const input = panel.querySelector("input")
          try {
            const url = new URL(input.value)
            if (!["http:", "https:", "mailto:"].includes(url.protocol)) throw new Error("Unsafe link")
            chain.extendMarkRange("link").setLink({href: url.href}).run()
            input.setCustomValidity("")
            panel.hidden = true
            input.value = ""
          } catch (_) {
            input.setCustomValidity(panel.dataset.invalidUrl)
            input.reportValidity()
          }
        },
        remove_link: () => {
          chain.extendMarkRange("link").unsetLink().run()
          const panel = this.el.querySelector("[data-part='link-controls']")
          panel.hidden = true
          panel.querySelector("input").value = ""
          panel.querySelector("input").setCustomValidity("")
        },
      }
      actions[command]?.()
      this.updateToolbar()
    }
    this.trackInput = event => {
      if (event.target.name?.startsWith("values[")) this.localDirty = true
    }
    this.submitting = () => this.rich?.setEditable(false, false)
    this.el.addEventListener("click", this.format)
    this.el.addEventListener("input", this.trackInput)
    this.el.addEventListener("submit", this.submitting)
    window.addEventListener("beforeunload", this.beforeUnload)
    document.addEventListener("click", this.beforeNavigate, true)
  },

  unsaved() {
    return this.localDirty || this.el.dataset.dirty === "true"
  },

  mountVisualEditor() {
    const surface = this.el.querySelector("[data-part='visual-surface']")
    this.baseMarkdown = this.bodyInput.value
    this.rich = new Editor({
      element: surface,
      extensions: [StarterKit.configure({underline: false, link: {openOnClick: false}}), Markdown,
        Image, TableKit, TaskList, TaskItem.configure({nested: true})],
      content: "",
      editable: !this.bodyInput.disabled,
      editorProps: {attributes: {role: "textbox", "aria-label": surface.dataset.label, "aria-multiline": "true", dir: "auto"}},
      onUpdate: () => {
        const unchanged = JSON.stringify(this.rich.getJSON()) === this.baseDocument
        this.bodyInput.value = unchanged ? this.baseMarkdown : this.rich.getMarkdown()
        this.bodyInput.dispatchEvent(new Event("input", {bubbles: true}))
        this.updateToolbar()
      },
      onSelectionUpdate: () => this.updateToolbar(),
    })
    // Unsupported constructs must stay untouched even when a sibling field changes.
    this.loadMarkdown(this.baseMarkdown)
  },

  loadMarkdown(markdown) {
    const tokens = this.rich.markdown.instance.lexer(markdown)
    let unsupported = false
    this.rich.markdown.instance.walkTokens(tokens, token => {
      if (token.type === "html" ||
          (!["code", "codespan"].includes(token.type) &&
            /(?<!\\)\[\^[^\]]+\]|&(?:#[0-9]+|#x[0-9a-f]+|[a-z][a-z0-9]+);/i.test(token.raw || ""))) unsupported = true
    })
    this.unsupported = unsupported
    this.baseMarkdown = markdown
    const surface = this.el.querySelector("[data-part='visual-surface']")
    surface.hidden = unsupported
    this.el.querySelector("[data-part='visual-warning']").hidden = !unsupported
    this.el.querySelector("[data-part='visual-fallback']").hidden = !unsupported
    if (unsupported) {
      this.el.querySelector("[data-part='visual-fallback']").innerHTML =
        this.el.querySelector("[data-part='fallback-content']").innerHTML
      this.rich.setEditable(false, false)
    } else {
      this.rich.commands.setContent(markdown, {contentType: "markdown", emitUpdate: false})
      this.baseDocument = JSON.stringify(this.rich.getJSON())
    }
    this.updateToolbar()
  },

  updateToolbar() {
    if (!this.rich) return
    for (const button of this.el.querySelectorAll("button[data-format]")) {
      const command = button.dataset.format
      const active = {heading: "heading", bold: "bold", italic: "italic", list: "bulletList", ordered: "orderedList", quote: "blockquote", link: "link"}[command]
      if (active) button.setAttribute("aria-pressed", String(this.rich.isActive(active)))
      button.disabled = this.unsupported || this.bodyInput.disabled ||
        (command === "undo" && !this.rich.can().undo()) || (command === "redo" && !this.rich.can().redo())
    }
  },

  updated() {
    this.localDirty = false
    if (!this.rich) return
    this.bodyInput = this.el.querySelector("input[name='values[body]']")
    if (this.el.dataset.dirty === "false" && this.bodyInput.value !== this.baseMarkdown) {
      this.loadMarkdown(this.bodyInput.value)
    }
    this.rich.setEditable(!this.bodyInput.disabled && !this.unsupported, false)
    this.updateToolbar()
  },

  destroyed() {
    this.rich?.destroy()
    this.el.removeEventListener("click", this.format)
    this.el.removeEventListener("input", this.trackInput)
    this.el.removeEventListener("submit", this.submitting)
    window.removeEventListener("beforeunload", this.beforeUnload)
    document.removeEventListener("click", this.beforeNavigate, true)
  }
}

export default ContentEditor
