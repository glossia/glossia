document.addEventListener("click", async event => {
  const button = event.target.closest("[data-mfa-copy]")
  if (!button) return
  const input = document.getElementById(button.dataset.mfaCopy)
  const status = document.querySelector("[data-mfa-copy-status]")
  try {
    await navigator.clipboard.writeText(input.value)
    status.textContent = status.dataset.copied
  } catch {
    input.focus()
    input.select()
    status.textContent = status.dataset.copyFailed
  }
})
