/**
 * Traffic bar chart for the selected analytics period.
 *
 * The server chooses hourly, daily, or monthly buckets based on the selected
 * period and includes empty buckets so quiet stretches keep their true width.
 * The container provides the series and granularity through data attributes.
 */

const NS = "http://www.w3.org/2000/svg"

const AnalyticsTraffic = {
  mounted() {
    this.observeCanvas()
    this.scheduleRender()
  },

  updated() {
    this.scheduleRender()
  },

  destroyed() {
    this.resizeObserver?.disconnect()
    cancelAnimationFrame(this.renderFrame)
  },

  observeCanvas() {
    const canvas = this.el.querySelector("#analytics-traffic-canvas")
    if (!canvas) return

    this.resizeObserver = new ResizeObserver(() => this.scheduleRender())
    this.resizeObserver.observe(canvas)
  },

  scheduleRender() {
    cancelAnimationFrame(this.renderFrame)
    this.renderFrame = requestAnimationFrame(() => this.render())
  },

  render() {
    const canvas = this.el.querySelector("#analytics-traffic-canvas")
    if (!canvas) return

    const series = this.parseSeries(canvas)
    const granularity = canvas.dataset.granularity || "day"
    canvas.innerHTML = ""

    if (series.length === 0) {
      this.renderEmptyState(canvas)
      return
    }

    const {width, height} = this.measureCanvas(canvas)
    const padding = {top: 16, right: 12, bottom: 24, left: 36}
    const innerW = width - padding.left - padding.right
    const innerH = height - padding.top - padding.bottom
    const max = Math.max(...series.map((s) => s.pageviews), 1)
    const barWidth = innerW / series.length

    const svg = document.createElementNS(NS, "svg")
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`)
    svg.setAttribute("width", "100%")
    svg.setAttribute("height", "100%")
    svg.setAttribute("role", "img")
    svg.setAttribute("aria-label", `Pageviews by ${granularity} for the selected period`)

    // Y-axis grid (3 lines).
    for (let i = 0; i <= 3; i++) {
      const y = padding.top + (innerH * i) / 3
      const line = document.createElementNS(NS, "line")
      line.setAttribute("x1", String(padding.left))
      line.setAttribute("x2", String(width - padding.right))
      line.setAttribute("y1", String(y))
      line.setAttribute("y2", String(y))
      line.setAttribute("stroke", "var(--noora-surface-border-primary)")
      line.setAttribute("stroke-width", "1")
      line.setAttribute("opacity", i === 3 ? "0.8" : "0.4")
      svg.appendChild(line)

      const label = document.createElementNS(NS, "text")
      label.setAttribute("x", String(padding.left - 8))
      label.setAttribute("y", String(y + 3))
      label.setAttribute("text-anchor", "end")
      label.setAttribute("font-size", "10")
      label.setAttribute("fill", "var(--noora-surface-label-secondary)")
      label.textContent = Math.round(max - (max * i) / 3).toString()
      svg.appendChild(label)
    }

    // Bars.
    series.forEach((point, index) => {
      const x = padding.left + index * barWidth
      const h = (point.pageviews / max) * innerH
      const y = padding.top + innerH - h

      const rect = document.createElementNS(NS, "rect")
      rect.setAttribute("x", String(x + 0.5))
      rect.setAttribute("y", String(y))
      rect.setAttribute("width", String(Math.max(1, barWidth - 1)))
      rect.setAttribute("height", String(h))
      rect.setAttribute("fill", "var(--noora-purple-500)")
      rect.setAttribute("fill-opacity", "0.85")
      rect.setAttribute("rx", "1.5")

      const title = document.createElementNS(NS, "title")
      title.textContent = `${this.formatBucketLabel(point.bucket, granularity, true)} — ${point.pageviews} pageviews, ${point.unique_visitors} unique visitors`
      rect.appendChild(title)
      svg.appendChild(rect)
    })

    // X-axis labels follow the bucket size selected for the period.
    const labelCount = Math.min(4, series.length)
    for (let i = 0; i < labelCount; i++) {
      const index =
        labelCount === 1 ? 0 : Math.floor((series.length - 1) * (i / (labelCount - 1)))
      const point = series[index]
      if (!point) continue

      const x = padding.left + index * barWidth + barWidth / 2
      const label = document.createElementNS(NS, "text")
      label.setAttribute("x", String(x))
      label.setAttribute("y", String(height - 6))
      label.setAttribute("text-anchor", "middle")
      label.setAttribute("font-size", "10")
      label.setAttribute("fill", "var(--noora-surface-label-secondary)")
      label.textContent = this.formatBucketLabel(point.bucket, granularity, false)
      svg.appendChild(label)
    }

    canvas.appendChild(svg)
  },

  parseSeries(canvas) {
    try {
      return JSON.parse(canvas.dataset.series || "[]")
    } catch {
      return []
    }
  },

  measureCanvas(canvas) {
    const rect = canvas.getBoundingClientRect()
    const width = Math.max(320, Math.round(rect.width))
    const height = Math.max(160, Math.round(rect.height || 180))
    return {width, height}
  },

  renderEmptyState(canvas) {
    const note = document.createElement("p")
    note.className = "voice-empty"
    note.textContent = "No traffic in the selected period."
    canvas.appendChild(note)
  },

  formatBucketLabel(bucket, granularity, detailed) {
    const date = new Date(bucket)

    if (granularity === "hour") {
      return new Intl.DateTimeFormat(undefined, {
        month: "short",
        day: "numeric",
        hour: "numeric",
        ...(detailed ? {minute: "2-digit"} : {}),
      }).format(date)
    }

    if (granularity === "month") {
      return new Intl.DateTimeFormat(undefined, {
        month: detailed ? "long" : "short",
        year: "numeric",
      }).format(date)
    }

    return new Intl.DateTimeFormat(undefined, {
      month: detailed ? "long" : "short",
      day: "numeric",
      ...(detailed ? {year: "numeric"} : {}),
    }).format(date)
  },
}

export default AnalyticsTraffic
