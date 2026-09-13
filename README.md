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

Read the complete feature and configuration reference in
[docs/usage.md](docs/usage.md).

The default terminal editor is `micro`. Docker shortcuts, directory tree
helpers, monitoring tools, and all shell commands are listed in the full
reference.

## Structure

- `linux/`: Bash and Zsh startup modules
- `windows/`: PowerShell modules and installers
- `shared/`: Starship, Git, and tmux configuration
- `packages/`: apt, dnf, and Winget package lists
- `.editorconfig` and `.gitattributes`: repository-wide file standards
