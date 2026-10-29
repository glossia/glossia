const illustration = document.querySelector("#error-illustration")

illustration.addEventListener("click", () => {
  const swapped = illustration.getAttribute("aria-pressed") === "true"
  illustration.setAttribute("aria-pressed", String(!swapped))
})
