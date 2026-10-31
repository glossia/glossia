import assert from "node:assert/strict"
import {readFile} from "node:fs/promises"
import test from "node:test"

const source = await readFile(new URL("../js/app_preview.js", import.meta.url), "utf8")
const {default: hook} = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`)

function mountPreview(t) {
  t.mock.timers.enable({apis: ["setTimeout", "setInterval", "Date"]})
  const sent = []
  const listeners = new Map()
  let focused = true
  let running = true
  const document = {
    visibilityState: "visible",
    hasFocus: () => focused,
    addEventListener: (event, callback) => listeners.set(event, callback),
    removeEventListener: event => listeners.delete(event),
    dispatch: event => listeners.get(event)?.(),
  }
  let rect = {left: 1000, top: 600, width: 240, height: 160}
  const frame = {
    id: "editor-app-frame",
    dataset: {revision: "1", status: "ready"},
    getBoundingClientRect: () => rect,
    closest: () => null,
  }
  const button = {setAttribute() {}, querySelector: () => ({textContent: ""})}
  const context = {
    ...hook,
    el: {
      ownerDocument: document,
      dataset: {expandLabel: "Expand", collapseLabel: "Shrink"},
      querySelector: selector => selector === "#editor-app-frame" ? frame
        : selector === "#editor-stop-preview" ? (running ? button : null) : button,
      addEventListener() {},
      removeEventListener() {},
    },
    pushEvent: (event, payload) => sent.push({event, payload}),
  }
  context.mounted()
  t.after(() => context.destroyed())
  const wheel = (overrides = {}) => context.wheel({
    target: frame, clientX: 1120, clientY: 680,
    deltaX: 0, deltaY: 20, deltaMode: 0, preventDefault() {}, ...overrides,
  })
  return {context, frame, sent, wheel, document, focus: value => { focused = value },
    stop: () => { running = false }, resize: value => { rect = value }}
}

test("only recent activity in a visible focused editor sends heartbeats", t => {
  const {context, sent, document, focus, stop} = mountPreview(t)
  t.mock.timers.tick(30000)
  assert.deepEqual(sent, [{event: "preview_heartbeat", payload: {}}])
  document.visibilityState = "hidden"
  document.dispatch("input")
  t.mock.timers.tick(30000)
  document.visibilityState = "visible"
  focus(false)
  document.dispatch("keydown")
  t.mock.timers.tick(30000)
  assert.equal(sent.length, 1)
  focus(true)
  document.dispatch("pointerdown")
  t.mock.timers.tick(30000)
  assert.equal(sent.length, 2)
  t.mock.timers.tick(60000)
  assert.equal(sent.length, 2)
  document.dispatch("wheel")
  t.mock.timers.tick(30000)
  assert.equal(sent.length, 3)
  stop()
  document.dispatch("input")
  t.mock.timers.tick(30000)
  assert.equal(sent.length, 3)
  context.destroyed()
  t.mock.timers.tick(30000)
  assert.equal(sent.length, 3)
})

test("wheel coordinates are normalized before expansion changes the image rectangle", t => {
  const {context, sent, wheel, resize} = mountPreview(t)
  wheel()
  context.toggle({target: {closest: () => true}})
  resize({left: 520, top: 280, width: 720, height: 480})
  t.mock.timers.tick(100)
  assert.deepEqual(sent, [{event: "preview_input", payload: {
    revision: 1, input: {type: "scroll", x: 600, y: 400, delta_x: 0, delta_y: 20},
  }}])
})

test("wheel batches retain the latest pointer position and bounded accumulated deltas", t => {
  const {sent, wheel} = mountPreview(t)
  wheel({deltaX: 100, deltaY: 100, deltaMode: 1})
  wheel({clientX: 1060, clientY: 640, deltaX: -10, deltaY: 10, deltaMode: 2})
  t.mock.timers.tick(100)
  assert.deepEqual(sent[0].payload, {
    revision: 1, input: {type: "scroll", x: 300, y: 200, delta_x: -1200, delta_y: 1200},
  })
  assert.equal(sent.length, 1)
})

test("queued wheel input is discarded when its revision changes or the frame stops being ready", t => {
  const {frame, sent, wheel} = mountPreview(t)
  wheel()
  frame.dataset.revision = "2"
  t.mock.timers.tick(100)
  wheel()
  frame.dataset.status = "updating"
  t.mock.timers.tick(100)
  assert.deepEqual(sent, [])
})

test("wheel deltas from an older revision do not accumulate into a new revision", t => {
  const {frame, sent, wheel} = mountPreview(t)
  wheel({deltaY: 100})
  frame.dataset.revision = "2"
  wheel({deltaY: 10})
  t.mock.timers.tick(100)
  assert.equal(sent.length, 1)
  assert.equal(sent[0].payload.revision, 2)
  assert.equal(sent[0].payload.input.delta_y, 10)
})

test("click and keyboard input keep the existing viewport coordinate contract", t => {
  const {context, frame, sent} = mountPreview(t)
  context.toggle({target: frame, clientX: 1060, clientY: 640})
  context.key({target: frame, key: "PageDown", preventDefault() {}})
  assert.deepEqual(sent.map(({payload}) => payload), [
    {revision: 1, input: {type: "click", x: 300, y: 200}},
    {revision: 1, input: {type: "scroll", x: 600, y: 400, delta_x: 0, delta_y: 640}},
  ])
})

test("invalid pointer positions, control-wheel gestures and destroyed hooks send nothing", t => {
  const {context, sent, wheel, resize} = mountPreview(t)
  wheel({clientX: 1240})
  wheel({clientY: 599})
  wheel({ctrlKey: true})
  resize({left: 1000, top: 600, width: 0, height: 0})
  wheel()
  t.mock.timers.tick(100)
  assert.deepEqual(sent, [])
  resize({left: 1000, top: 600, width: 240, height: 160})
  wheel()
  context.destroyed()
  t.mock.timers.tick(100)
  assert.deepEqual(sent, [])
})
