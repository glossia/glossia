/**
 * Localization-priority map.
 *
 * Renders a world dot map with one marker per country. Each marker combines
 * its locale-gap visits, while its hover card lists the browser languages
 * that most need translation in that country. Markers are positioned by the
 * country's centroid and sized + colored by the combined priority score:
 *
 *     priority_score = visitors * (1 - english_score)
 *
 * The hook is intentionally tiny: no React, no D3 selection, just raw SVG.
 * The container provides the data via a `data-priority` attribute so the
 * hook is self-contained and re-mounts cleanly on LiveView navigation.
 */

import {geoNaturalEarth1, geoPath} from "d3-geo"
import {feature} from "topojson-client"
import worldAtlas from "world-atlas/countries-110m.json"

const NS = "http://www.w3.org/2000/svg"
const MAX_DOT_RADIUS = 18
const MIN_DOT_RADIUS = 4

const LocalizationPriorityMap = {
  mounted() {
    this.render()
  },

  updated() {
    this.render()
  },

  render() {
    const canvas = this.el.querySelector("#localization-priority-map-canvas")
    if (!canvas) return

    const points = this.aggregateCountries(this.parsePoints(canvas))
    canvas.innerHTML = ""

    if (points.length === 0) {
      this.renderEmptyState(canvas)
      return
    }

    const {width, height} = this.measureCanvas(canvas)
    const projection = geoNaturalEarth1().fitSize([width, height], {type: "Sphere"})
    const path = geoPath(projection)

    const countries = feature(worldAtlas, worldAtlas.objects.countries)
    const svg = this.buildSvg(width, height, path, countries)

    svg.addEventListener("pointerleave", () => this.hideActiveTooltip())

    points.forEach((point) => {
      const projected = projection(point.centroid)
      if (!projected) return

      const [x, y] = projected
      const radius = this.scaleRadius(point.priority_score, points)
      const color = this.colorForPriority(point.english_score)
      const dot = this.buildDot(x, y, radius, color, point, width, height)
      svg.appendChild(dot)
    })

    canvas.appendChild(svg)
  },

  parsePoints(canvas) {
    try {
      return JSON.parse(canvas.dataset.priority || "[]")
    } catch {
      return []
    }
  },

  aggregateCountries(points) {
    const countries = new Map()

    points.forEach((point) => {
      const country = countries.get(point.country_code) || {
        country_code: point.country_code,
        country_name: point.country_name,
        centroid: point.centroid,
        visitors: 0,
        priority_score: 0,
        english_score_total: 0,
        recommendations: [],
      }

      country.visitors += point.visitors
      country.priority_score += point.priority_score
      country.english_score_total += point.english_score * point.visitors
      country.recommendations.push({
        language: point.browser_language,
        visitors: point.visitors,
        priority_score: point.priority_score,
      })

      countries.set(point.country_code, country)
    })

    return [...countries.values()].map((country) => ({
      ...country,
      english_score:
        country.visitors === 0 ? 0 : country.english_score_total / country.visitors,
      recommendations: country.recommendations
        .sort((left, right) => right.priority_score - left.priority_score)
        .slice(0, 3),
    }))
  },

  measureCanvas(canvas) {
    const rect = canvas.getBoundingClientRect()
    const width = Math.max(320, Math.round(rect.width))
    const height = Math.round(width / 2)
    return {width, height}
  },

  buildSvg(width, height, path, countries) {
    const svg = document.createElementNS(NS, "svg")
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`)
    svg.setAttribute("width", "100%")
    svg.setAttribute("height", "100%")
    svg.setAttribute("role", "img")
    svg.setAttribute("aria-label", "Localization priority by country")

    // A subtle ocean rectangle so the SVG reads as a map, not floating dots.
    const ocean = document.createElementNS(NS, "rect")
    ocean.setAttribute("x", "0")
    ocean.setAttribute("y", "0")
    ocean.setAttribute("width", String(width))
    ocean.setAttribute("height", String(height))
    ocean.setAttribute("fill", "var(--noora-surface-background-secondary)")
    ocean.setAttribute("rx", "12")
    svg.appendChild(ocean)

    const land = document.createElementNS(NS, "path")
    land.setAttribute("d", path(countries))
    land.setAttribute("fill", "var(--noora-surface-background-primary)")
    land.setAttribute("stroke", "var(--noora-content-divider-line)")
    land.setAttribute("stroke-width", "0.75")
    svg.appendChild(land)

    // Faint outline frames the projection without competing with country borders.
    const graticule = path({type: "Sphere"}) || ""
    if (graticule) {
      const sphere = document.createElementNS(NS, "path")
      sphere.setAttribute("d", graticule)
      sphere.setAttribute("fill", "none")
      sphere.setAttribute("stroke", "var(--noora-surface-border-primary)")
      sphere.setAttribute("stroke-width", "1")
      sphere.setAttribute("opacity", "0.6")
      svg.appendChild(sphere)
    }

    return svg
  },

  scaleRadius(score, points) {
    if (points.length === 0) return MIN_DOT_RADIUS
    const maxScore = Math.max(...points.map((p) => p.priority_score), 1)
    const ratio = Math.sqrt(score / maxScore)
    return MIN_DOT_RADIUS + (MAX_DOT_RADIUS - MIN_DOT_RADIUS) * ratio
  },

  colorForPriority(englishScore) {
    // 1.0 = perfect English tolerance = low priority = light pink.
    // 0.0 = no tolerance = high priority = deep pink.
    const intensity = 1 - englishScore
    if (intensity < 0.3) return "var(--noora-pink-200)"
    if (intensity < 0.5) return "var(--noora-pink-300)"
    if (intensity < 0.7) return "var(--noora-pink-500)"
    return "var(--noora-pink-700)"
  },

  buildDot(x, y, radius, fill, point, width, height) {
    const group = document.createElementNS(NS, "g")
    group.setAttribute("tabindex", "0")
    group.setAttribute("role", "img")
    group.setAttribute("aria-label", this.priorityLabel(point))

    const dot = document.createElementNS(NS, "circle")
    dot.setAttribute("cx", String(x))
    dot.setAttribute("cy", String(y))
    dot.setAttribute("r", String(radius))
    dot.setAttribute("fill", fill)
    dot.setAttribute("fill-opacity", "0.78")
    dot.setAttribute("stroke", "var(--noora-pink-900)")
    dot.setAttribute("stroke-width", "0.5")
    dot.setAttribute("stroke-opacity", "0.25")

    const tooltip = this.buildTooltip(x, y, radius, point, width, height)
    tooltip.setAttribute("visibility", "hidden")

    const showTooltip = () => {
      this.hideActiveTooltip()
      group.parentNode?.appendChild(group)
      dot.setAttribute("stroke-width", "2")
      dot.setAttribute("stroke-opacity", "0.8")
      tooltip.setAttribute("visibility", "visible")
      this.activeTooltip = hideTooltip
    }

    const hideTooltip = () => {
      dot.setAttribute("stroke-width", "0.5")
      dot.setAttribute("stroke-opacity", "0.25")
      tooltip.setAttribute("visibility", "hidden")

      if (this.activeTooltip === hideTooltip) {
        this.activeTooltip = null
      }
    }

    group.addEventListener("pointerenter", showTooltip)
    group.addEventListener("pointerleave", hideTooltip)
    group.addEventListener("focus", showTooltip)
    group.addEventListener("blur", hideTooltip)

    group.appendChild(dot)
    group.appendChild(tooltip)

    dot.style.cursor = "pointer"
    return group
  },

  buildTooltip(x, y, radius, point, width, height) {
    const country = point.country_name
    const recommendations = point.recommendations.map((recommendation) =>
      this.recommendationLabel(recommendation),
    )
    const tooltipWidth = Math.max(country.length * 7, ...recommendations.map((label) => label.length * 7)) + 20
    const tooltipHeight = 30 + recommendations.length * 17
    const tooltipX = Math.min(x + radius + 10, width - tooltipWidth - 8)
    const tooltipY = Math.max(8, Math.min(y - tooltipHeight / 2, height - tooltipHeight - 8))

    const tooltip = document.createElementNS(NS, "g")
    tooltip.setAttribute("pointer-events", "none")

    const background = document.createElementNS(NS, "rect")
    background.setAttribute("x", String(tooltipX))
    background.setAttribute("y", String(tooltipY))
    background.setAttribute("width", String(tooltipWidth))
    background.setAttribute("height", String(tooltipHeight))
    background.setAttribute("rx", "6")
    background.setAttribute("fill", "var(--noora-surface-background-primary)")
    background.setAttribute("stroke", "var(--noora-surface-border-primary)")
    background.setAttribute("stroke-width", "1")

    const countryLabel = document.createElementNS(NS, "text")
    countryLabel.setAttribute("x", String(tooltipX + 10))
    countryLabel.setAttribute("y", String(tooltipY + 17))
    countryLabel.setAttribute("fill", "var(--noora-surface-label-primary)")
    countryLabel.setAttribute("font-size", "12")
    countryLabel.setAttribute("font-family", "var(--noora-font-body)")
    countryLabel.setAttribute("font-weight", "600")
    countryLabel.textContent = `${this.countryFlag(point.country_code)} ${country}`

    tooltip.appendChild(background)
    tooltip.appendChild(countryLabel)

    recommendations.forEach((recommendation, index) => {
      const recommendationLabel = document.createElementNS(NS, "text")
      recommendationLabel.setAttribute("x", String(tooltipX + 10))
      recommendationLabel.setAttribute("y", String(tooltipY + 34 + index * 17))
      recommendationLabel.setAttribute("fill", "var(--noora-surface-label-secondary)")
      recommendationLabel.setAttribute("font-size", "11")
      recommendationLabel.setAttribute("font-family", "var(--noora-font-body)")
      recommendationLabel.textContent = recommendation
      tooltip.appendChild(recommendationLabel)
    })

    return tooltip
  },

  hideActiveTooltip() {
    this.activeTooltip?.()
  },

  priorityLabel(point) {
    const visitors = point.visitors.toLocaleString()
    const englishPct = Math.round((point.english_score || 0) * 100)
    const priority = point.priority_score.toLocaleString()
    const recommendations = point.recommendations
      .map((recommendation) => this.recommendationLabel(recommendation))
      .join(", ")

    return (
      `${point.country_name}: ${recommendations}. ` +
      `${visitors} visitors, ${englishPct}% English tolerance, priority ${priority}.`
    )
  },

  recommendationLabel(recommendation) {
    return `${this.languageName(recommendation.language)} · ${recommendation.visitors.toLocaleString()} visitors`
  },

  languageName(language) {
    try {
      return new Intl.DisplayNames(["en"], {type: "language"}).of(language) || language
    } catch {
      return language
    }
  },

  countryFlag(countryCode) {
    if (!/^[A-Z]{2}$/.test(countryCode || "")) return ""

    return String.fromCodePoint(
      ...countryCode
        .split("")
        .map((letter) => 0x1f1e6 + letter.charCodeAt(0) - "A".charCodeAt(0)),
    )
  },

  renderEmptyState(canvas) {
    const note = document.createElement("p")
    note.className = "voice-empty"
    note.textContent =
      "No locale-gap visits in the last 30 days. Once visitors land on a page in a language the project does not serve, they will appear here."
    canvas.appendChild(note)
  },
}

export default LocalizationPriorityMap
