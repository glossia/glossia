import assert from "node:assert/strict"
import {readFile} from "node:fs/promises"
import test from "node:test"

const source = await readFile(new URL("../js/signup_turnstile.js", import.meta.url), "utf8")

for (const submitBeforeVerification of [false, true]) {
  test(`submits the solved challenge token when verification ${submitBeforeVerification ? "follows" : "precedes"} submit`, async () => {
    let verify
    let submit
    let submittedToken
    const input = {value: ""}
    const status = {textContent: ""}
    const root = {dataset: {sitekey: "test"}, querySelector: () => status}
    const form = {
      addEventListener: (_event, listener) => { submit = listener },
      requestSubmit: () => {
        let prevented = false
        submit({preventDefault: () => { prevented = true }})
        if (!prevented) submittedToken = input.value
      },
    }
    globalThis.document = {
      querySelector: () => root,
      querySelectorAll: selector => selector.includes("interest-form") ? [form] : [input],
    }
    globalThis.window = {turnstile: {render: (_root, options) => { verify = options.callback; return 1 }}}
    const {default: initialize} = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}#${submitBeforeVerification}`)
    initialize()
    await Promise.resolve()
    if (submitBeforeVerification) {
      form.requestSubmit()
      assert.equal(submittedToken, undefined)
    }
    verify("solved-token")
    if (!submitBeforeVerification) form.requestSubmit()
    assert.equal(submittedToken, "solved-token")
    delete globalThis.document
    delete globalThis.window
  })
}
