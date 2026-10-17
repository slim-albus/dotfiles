# Dotfiles

Personal shell and developer configuration for Linux, WSL, and Windows
PowerShell.

## Install

Linux or WSL:

```bash
./install-packages.sh
./install.sh
```

Windows PowerShell:

```powershell
.\windows\install-packages.ps1
.\windows\install.ps1
```

Use `--dry-run` or `-DryRun` to preview changes. Package lists live in
`packages/`; edit the file for your package manager before installing.
Use `./install-packages.sh --minimal` for the essential shell baseline, or
`--log FILE` to capture installer output.

Read the complete feature and configuration reference in
[docs/usage.md](docs/usage.md).

Type `dots` (or `cheat`) in PowerShell anytime for your instant interactive
command reference, or `dots doctor` to check your environment health.

The default terminal editor is `micro`. Docker shortcuts, directory tree
helpers, monitoring tools (`fastfetch`), and all shell commands are listed
in the full reference.

## Structure

- `linux/`: Bash and Zsh startup modules
- `windows/`: PowerShell modules, `dots` manual, and visual installers
- `wsl/`: WSL system configuration (`.wslconfig`)
- `shared/`: Starship, Fastfetch, Git, Micro, and tmux configuration
- `packages/`: apt, dnf, and Winget package lists
- `.editorconfig` and `.gitattributes`: repository-wide file standards
