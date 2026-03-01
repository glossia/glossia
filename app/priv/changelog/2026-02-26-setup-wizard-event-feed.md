%{
  title: "Setup wizard now shows structured agent events and PR links",
  summary: "Project setup now highlights prompt goals, uses cleaner event cards, and surfaces the generated pull request link."
}
---

The project setup experience is now easier to review while the agent runs:

- The setup step shows a concise objective checklist before events stream in.
- Agent events are rendered as structured cards with badges (`Prompt`, `Status`, `Tool`, `Tool output`, `Pull request`).
- The setup backend emits a dedicated `pr_created` event so the UI can reliably show an **Open pull request** link.

The setup prompt was also tightened to produce a minimal, reference-ready `GLOSSIA.md` aligned with selected target languages and the documented `GLOSSIA.md` structure.
