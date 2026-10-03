import assert from "node:assert/strict"
import {readFile} from "node:fs/promises"
import test from "node:test"

const source = await readFile(new URL("../js/analytics_map.js", import.meta.url), "utf8")
// These tests exercise sizing and aggregation without loading the atlas or DOM.
const hookSource = source.replace(/^import .*$/gm, "")
const {default: map} = await import(`data:text/javascript;base64,${Buffer.from(hookSource).toString("base64")}`)

test("the map preserves its aspect ratio at the full available card width", () => {
  assert.deepEqual(map.measureCanvas({getBoundingClientRect: () => ({width: 1600})}), {
    width: 1600, height: 800,
  })
})

test("the map does not overflow narrow mobile containers", () => {
  assert.deepEqual(map.measureCanvas({getBoundingClientRect: () => ({width: 240})}), {
    width: 240, height: 120,
  })
})

test("language opportunities aggregate into one country marker", () => {
  const countries = map.aggregateCountries([
    {country_code: "DE", country_name: "Germany", centroid: [10, 51], visitors: 10, priority_score: 5, english_score: 0.5, browser_language: "ja"},
    {country_code: "DE", country_name: "Germany", centroid: [10, 51], visitors: 4, priority_score: 2, english_score: 0.5, browser_language: "ko"},
  ])
  assert.equal(countries.length, 1)
  assert.equal(countries[0].visitors, 14)
  assert.equal(countries[0].priority_score, 7)
  assert.deepEqual(countries[0].recommendations.map(row => row.language), ["ja", "ko"])
})
