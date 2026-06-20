---
locale: es
model: "openai/gpt-5"
validation:
  - "./scripts/check-es.sh"
  - "--max-length"
  - "120"
---

## Spanish-specific translation rules

- Translate "workspace" as "espacio de trabajo".
- Translate "string set" as "conjunto de cadenas".
- Keep "ship review" in English when it appears as a feature label.
