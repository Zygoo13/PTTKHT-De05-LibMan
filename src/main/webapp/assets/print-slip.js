const printButton = document.getElementById("print-slip");
if (printButton) {
    printButton.addEventListener("click", () => window.print());
}
