%{
  title: "Native avatar picker on profile",
  summary: "Reworked profile avatar upload to use a standard browser file picker flow for better Chrome compatibility."
}
---

The profile avatar section now uses a dedicated native multipart form with a standard file input and submit action. This avoids custom upload picker behavior and improves reliability in Chrome while keeping the same image validation and avatar storage behavior.
