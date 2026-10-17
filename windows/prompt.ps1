# ============================================================
# Prompt (Starship with Fallback)
# ============================================================

if ($global:IsInteractiveShell) {
    if (Get-Command starship.exe -ErrorAction SilentlyContinue) {
        Invoke-Expression (&starship init powershell)
    } else {
        function global:prompt {
            $loc = (Get-Location).ProviderPath
            $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            $symbol = if ($isAdmin) { '# ' } else { '❯ ' }
            Write-Host $loc -ForegroundColor Cyan -NoNewline
            Write-Host " $symbol" -ForegroundColor Green -NoNewline
            return " "
        }
    }
}