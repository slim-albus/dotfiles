# ============================================================
# Prompt (Starship)
# ============================================================

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}