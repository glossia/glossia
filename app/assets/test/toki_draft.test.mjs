import assert from "node:assert/strict"
import {readFile} from "node:fs/promises"
import test from "node:test"

const source = await readFile(new URL("../js/toki_draft.js", import.meta.url), "utf8")
const {default: hook} = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`)

function mountDraft(id = "toki-composer") {
  const stored = new Map()
  const handlers = new Map()
  let focused = false
  const textarea = {value: "", focus: () => { focused = true }}
  globalThis.sessionStorage = {
    getItem: key => stored.get(key) ?? null,
    setItem: (key, value) => stored.set(key, value),
    removeItem: key => stored.delete(key),
  }
  const context = {
    ...hook,
    el: {
      id,
      dataset: {draftKey: "actor:project:conversation:message"},
      querySelector: selector => selector === "textarea" ? textarea : null,
      addEventListener() {},
      removeEventListener() {},
    },
    handleEvent: (name, handler) => handlers.set(name, handler),
  }
  context.mounted()
  return {context, stored, handlers, textarea, isFocused: () => focused}
}

test("a conversation starter focuses and persists the suggested draft, then clears after sending", () => {
  const {context, stored, handlers, textarea, isFocused} = mountDraft()
  try {
    const content = "Can you help me review this translation?\n\n"
    handlers.get("toki-draft-suggested")({content})
    assert.equal(textarea.value, content)
    assert.equal(isFocused(), true)
    assert.deepEqual(JSON.parse(stored.get(context.key)), {text: content})

    handlers.get("toki-draft-saved")({form: "toki-composer"})
    assert.equal(textarea.value, "")
    assert.equal(stored.has(context.key), false)
  } finally {
    context.destroyed()
    delete globalThis.sessionStorage
  }
})

test("the guidance draft does not listen for conversation starters", () => {
  const {context, handlers} = mountDraft("toki-resolution")
  try {
    assert.equal(handlers.has("toki-draft-suggested"), false)
  } finally {
    context.destroyed()
    delete globalThis.sessionStorage
  }
})

test("a starter still focuses the composer when browser storage is unavailable", () => {
  const {context, handlers, textarea, isFocused} = mountDraft()
  globalThis.sessionStorage.setItem = () => { throw new Error("Storage disabled") }
  try {
    handlers.get("toki-draft-suggested")({content: "Suggested draft"})
    assert.equal(textarea.value, "Suggested draft")
    assert.equal(isFocused(), true)
  } finally {
    context.destroyed()
    delete globalThis.sessionStorage
  }
})
