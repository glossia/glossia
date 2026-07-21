const normalizeSearchText = value =>
  value
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim()

const editDistance = (left, right) => {
  const rows = Array.from({length: left.length + 1}, (_, index) => index)

  for (let rightIndex = 1; rightIndex <= right.length; rightIndex += 1) {
    let previousDiagonal = rows[0]
    rows[0] = rightIndex

    for (let leftIndex = 1; leftIndex <= left.length; leftIndex += 1) {
      const previousRow = rows[leftIndex]
      const substitution = previousDiagonal + (left[leftIndex - 1] === right[rightIndex - 1] ? 0 : 1)
      rows[leftIndex] = Math.min(rows[leftIndex] + 1, rows[leftIndex - 1] + 1, substitution)
      previousDiagonal = previousRow
    }
  }

  return rows[left.length]
}

const scoreTerm = (term, words) => {
  if (words.includes(term)) return 100
  if (words.some(word => word.startsWith(term))) return 80
  if (words.some(word => word.includes(term))) return 60

  const allowedDistance = term.length >= 8 ? 2 : term.length >= 4 ? 1 : 0
  if (allowedDistance === 0) return null

  const closestDistance = words.reduce(
    (closest, word) => Math.min(closest, editDistance(term, word)),
    Number.POSITIVE_INFINITY
  )

  return closestDistance <= allowedDistance ? 30 - closestDistance : null
}

export const modelSearchScore = ([label, value], filter) => {
  const query = normalizeSearchText(filter || "")
  if (query === "") return 0

  const labelText = normalizeSearchText(label)
  const searchable = normalizeSearchText(`${label} ${value}`)
  const words = searchable.split(" ")
  const terms = query.split(" ")
  let score = 0
  let matchedTerms = 0

  for (const term of terms) {
    const termScore = scoreTerm(term, words)
    if (termScore !== null) {
      score += termScore
      matchedTerms += 1
    }
  }

  if (matchedTerms === 0) return null

  score += matchedTerms * 200
  if (matchedTerms === terms.length) score += 500
  if (searchable.includes(query)) score += 300
  if (labelText.includes(query)) score += 200
  if (labelText.startsWith(query)) score += 100

  return score
}

export default {
  mounted() {
    this.options = JSON.parse(this.el.dataset.options || "[]")
    this.resultLimit = Number.parseInt(this.el.dataset.resultLimit || "50", 10)
    this.currentValue = this.el.dataset.value || ""
    this.trigger = this.el.querySelector('[data-part="trigger"]')
    this.label = this.trigger.querySelector('[data-part="label"]')
    this.indicator = this.trigger.querySelector('[data-part="indicator"]')
    this.content = this.el.querySelector('[data-part="content"]')
    this.search = this.el.querySelector('[data-part="search-input"]')
    this.search.autocomplete = "off"
    this.items = this.el.querySelector('[data-part="items"]')
    this.hidden = this.el.querySelector('[data-part="value"]')
    this.optionIcon = this.el.querySelector('[data-part="option-icon-template"]')
    this.selectedIcon = this.el.querySelector('[data-part="selected-icon-template"]')
    this.highlighted = -1

    this.onTriggerClick = () => this.isOpen() ? this.close() : this.open()
    this.onTriggerKeydown = (event) => {
      if (["ArrowDown", "Enter", " "].includes(event.key)) {
        event.preventDefault()
        this.open()
      }
    }
    this.onSearchInput = (event) => {
      event.stopPropagation()
      this.renderOptions(this.search.value)
    }
    this.onSearchChange = (event) => event.stopPropagation()
    this.onSearchKeydown = (event) => this.handleSearchKeydown(event)
    this.onOutsidePointerDown = (event) => {
      if (!this.el.contains(event.target)) this.close()
    }

    this.trigger.addEventListener("click", this.onTriggerClick)
    this.trigger.addEventListener("keydown", this.onTriggerKeydown)
    this.search.addEventListener("input", this.onSearchInput)
    this.search.addEventListener("change", this.onSearchChange)
    this.search.addEventListener("keydown", this.onSearchKeydown)
    document.addEventListener("pointerdown", this.onOutsidePointerDown)
    this.syncValue()
  },

  updated() {
    this.currentValue = this.el.dataset.value || ""
    this.syncValue()
    if (this.isOpen()) this.renderOptions(this.search.value)
  },

  destroyed() {
    this.trigger.removeEventListener("click", this.onTriggerClick)
    this.trigger.removeEventListener("keydown", this.onTriggerKeydown)
    this.search.removeEventListener("input", this.onSearchInput)
    this.search.removeEventListener("change", this.onSearchChange)
    this.search.removeEventListener("keydown", this.onSearchKeydown)
    document.removeEventListener("pointerdown", this.onOutsidePointerDown)
  },

  isOpen() {
    return this.trigger.dataset.state === "open"
  },

  open() {
    this.trigger.dataset.state = "open"
    this.indicator.dataset.state = "open"
    this.content.dataset.state = "open"
    this.trigger.setAttribute("aria-expanded", "true")
    this.search.setAttribute("aria-expanded", "true")
    this.search.value = ""
    this.renderOptions("")
    window.requestAnimationFrame(() => this.search.focus())
  },

  close() {
    delete this.trigger.dataset.state
    delete this.indicator.dataset.state
    delete this.content.dataset.state
    this.trigger.setAttribute("aria-expanded", "false")
    this.search.setAttribute("aria-expanded", "false")
    this.search.removeAttribute("aria-activedescendant")
    this.highlighted = -1
  },

  syncValue() {
    this.hidden.value = this.currentValue
    const selected = this.options.find(([_label, value]) => value === this.currentValue)
    this.label.textContent = selected ? selected[0] : this.el.dataset.placeholder
  },

  renderOptions(filter) {
    const query = normalizeSearchText(filter || "")
    const matches = query === ""
      ? this.options
      : this.options
          .map(option => [option, modelSearchScore(option, query)])
          .filter(([_option, score]) => score !== null)
          .sort(([leftOption, leftScore], [rightOption, rightScore]) =>
            rightScore - leftScore || leftOption[0].localeCompare(rightOption[0])
          )
          .map(([option]) => option)
    const visible = matches.slice(0, this.resultLimit)

    this.items.replaceChildren()
    this.highlighted = -1
    this.search.removeAttribute("aria-activedescendant")

    visible.forEach(([label, value], index) => {
      const option = document.createElement("button")
      option.type = "button"
      option.id = `${this.el.id}-option-${index}`
      option.className = "noora-dropdown-item"
      option.dataset.part = "item"
      option.dataset.size = "small"
      option.dataset.value = value
      option.setAttribute("role", "option")
      option.setAttribute("aria-selected", String(value === this.currentValue))
      option.tabIndex = -1

      const leftIcon = document.createElement("span")
      leftIcon.dataset.part = "left-icon"
      leftIcon.append(this.optionIcon.content.cloneNode(true))
      option.append(leftIcon)

      const content = document.createElement("span")
      content.dataset.part = "content"
      const body = document.createElement("span")
      body.dataset.part = "body"
      const labelElement = document.createElement("span")
      labelElement.dataset.part = "label"
      labelElement.textContent = label
      body.append(labelElement)
      content.append(body)
      option.append(content)

      if (value === this.currentValue) {
        const rightIcon = document.createElement("span")
        rightIcon.dataset.part = "right-icon"
        rightIcon.append(this.selectedIcon.content.cloneNode(true))
        option.append(rightIcon)
      }

      option.addEventListener("pointerenter", () => this.highlightAt(index))
      option.addEventListener("mousedown", (event) => event.preventDefault())
      option.addEventListener("click", () => this.pick(label, value))
      this.items.append(option)
    })

    if (matches.length === 0) {
      const empty = document.createElement("span")
      empty.dataset.part = "search-empty"
      empty.textContent = this.el.dataset.emptyLabel
      this.items.append(empty)
    } else if (matches.length > this.resultLimit) {
      const summary = document.createElement("span")
      summary.dataset.part = "search-status"
      summary.setAttribute("role", "status")
      summary.textContent = this.el.dataset.resultSummary
      this.items.append(summary)
    }
  },

  renderedOptions() {
    return [...this.items.querySelectorAll('[data-part="item"]')]
  },

  highlightAt(index) {
    const options = this.renderedOptions()
    options.forEach((option) => delete option.dataset.highlighted)
    if (index < 0 || index >= options.length) return

    this.highlighted = index
    options[index].dataset.highlighted = "true"
    options[index].scrollIntoView({block: "nearest"})
    this.search.setAttribute("aria-activedescendant", options[index].id)
  },

  handleSearchKeydown(event) {
    event.stopPropagation()
    const options = this.renderedOptions()

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.highlightAt(Math.min(this.highlighted + 1, options.length - 1))
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.highlightAt(Math.max(this.highlighted - 1, 0))
    } else if (event.key === "Enter" && this.highlighted >= 0) {
      event.preventDefault()
      const option = options[this.highlighted]
      this.pick(option.querySelector('[data-part="label"]').textContent, option.dataset.value)
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.close()
      this.trigger.focus()
    } else if (event.key === "Tab") {
      this.close()
    }
  },

  pick(label, value) {
    this.currentValue = value
    this.hidden.value = value
    this.label.textContent = label
    this.close()
    this.hidden.dispatchEvent(new Event("input", {bubbles: true}))
    this.trigger.focus()
  }
}
