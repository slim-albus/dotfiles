# Dotfiles Usage

This document is the detailed reference for the repository. The root
[README](../README.md) intentionally contains only the quick start.

## Installation

### Linux and WSL

`install-packages.sh` detects `apt` or `dnf`, reads the matching manifest, and
installs packages with `sudo`. `git` is required for the setup scripts and is
checked before installation; optional convenience packages are attempted
individually and skipped if unavailable.

```bash
./install-packages.sh
./install-packages.sh --minimal
```

`install.sh` installs user configuration without requiring root:

```bash
./install.sh
```

Before changing any files, `install.sh` verifies the core tool it needs for
optional Oh My Zsh setup: `git`. The remaining manifest packages are optional
interactive conveniences and do not block configuration installation. Debian's
`fd-find` command is available as `fdfind`; Fedora's is available as `fd`.

Preview either operation first:

```bash
./install-packages.sh --dry-run
./install.sh --dry-run
./install.sh --log "$HOME/.local/state/dotfiles-install.log"
```

Use `--minimal` to install only `git`, `zsh`, `curl`, and `micro`. The default
is `--full`, which attempts the optional tools in the selected manifest. Pass
`--log FILE` to either installer to append its output to a log file.

The configuration installer links Starship, Git, Git's global ignore file, and
tmux into `${XDG_CONFIG_HOME:-$HOME/.config}`. It always configures `~/.bashrc`
and configures `~/.zshrc` plus Oh My Zsh when Zsh is installed. It also
installs `zsh-autosuggestions` and `zsh-autocomplete` into `~/.oh-my-zsh` when
Git is available. Existing Oh My Zsh installations and plugin directories are
left untouched.
Existing link targets are moved to `.dotfiles-backup`; a timestamp is added if
that backup name already exists.

### Windows PowerShell

`windows/install-packages.ps1` installs packages from `packages/winget.txt` with
pre-flight binary checks, visual colored progress indicators (`[ OK ]`, `[SKIP]`, `[FAIL]`),
error resilience (continues installing even if an optional tool fails), and a final summary:

```powershell
.\windows\install-packages.ps1
.\windows\install-packages.ps1 -Minimal
.\windows\install-packages.ps1 -DryRun
```

`windows/install.ps1` safely configures your environment:
1. Detects `$PROFILE.CurrentUserCurrentHost` (including Chris Titus Tech CTT profile),
   creates a timestamped backup (`.ctt-backup.<timestamp>`), and installs a clean single-source loader.
2. Configures Git shared settings (`shared/git/config`) and global ignore (`shared/git/ignore`).
3. Syncs WSL configuration (`wsl/.wslconfig` to `$HOME\.wslconfig`).
4. Runs automated health verification (`Invoke-DotfilesDoctor`):

```powershell
.\windows\install.ps1
.\windows\install.ps1 -DryRun
.\windows\install.ps1 -TrackWsl
```

Pass `-LogFile FILE` to either installer to write an execution transcript.

## Package Manifests

Each package manager has its own native manifest:

| Manager | File | Contents |
| --- | --- | --- |
| apt | `packages/apt.txt` | Debian/Ubuntu package names |
| dnf | `packages/dnf.txt` | Fedora/RHEL package names |
| Winget | `packages/winget.txt` | Exact Winget IDs |

Use one entry per line. Blank lines and comments beginning with `#` are
ignored. Keep the files separate because package names and identifiers differ
between ecosystems.

## Shell Startup

Linux and WSL load these files through `linux/bashrc` or `linux/zshrc`:

- `env.sh`: editor, pager, Starship path, and PATH additions.
- `aliases.sh`: navigation, listings, Git shortcuts, and grep coloring.
- `functions.sh`: reusable development commands.
- `prompt.sh`: Starship initialization.

`bashrc` loads the system Bash completion definitions when installed. `zshrc`
enables Zsh's built-in `compinit`, case-insensitive matching, menu selection,
and a cached completion dump under `${XDG_CACHE_HOME:-$HOME/.cache}/zsh`.
When available, Oh My Zsh loads the Git, `zsh-autosuggestions`, and
`zsh-autocomplete` plugins. Starship remains the only prompt provider; Oh My
Zsh's theme is disabled.
The Bash startup file is always configured; the Zsh startup file is configured
when Zsh is installed.

PowerShell uses the equivalent modules:

- `env.ps1`
- `aliases.ps1`
- `functions.ps1`
- `modules.ps1`
- `prompt.ps1`

Reload a Unix shell with `reload`. Reload PowerShell with `reload` as well.

## Commands

### Navigation and files

| Command | Purpose |
| --- | --- |
| `..`, `...`, `....` | Move up one, two, or three directories |
| `up [N]` | Move up `N` directories |
| `mkcd DIR` | Create a directory and enter it |
| `project_root` | Print the Git root, or the current directory outside Git |
| `croot` | Change to the current Git repository root |
| `l`, `la`, `ll` | Directory listings, including hidden files for `la` and `ll` |
| `cls` | Clear the terminal screen |
| `bigfiles [DIR] [N]` | Show the largest entries; defaults to 20 |
| `treeview [DIR] [FILE]` | Print a directory tree or save it to a text file |
| `Show-Tree [PATH] [OUTPUT_FILE]` | Print a directory tree or save it to a text file |
| `path` | Print PATH entries one per line |
| `extract ARCHIVE` | Extract tar, zip, gzip, bzip2, and xz archives |

PowerShell equivalents include `Get-BigFiles` and `Show-Path`.

### Interactive Manual & Cheat Sheet (`dots`)

Run `dots` (or `cheat`) in PowerShell anytime to open the interactive command reference:

```powershell
dots                   # View full categorized cheat sheet
dots git               # Filter Git shortcuts
dots nav               # Filter navigation shortcuts
dots sys               # Filter system and Windows tools
dots keys              # View autocomplete keybindings
dots find <term>       # Search across all commands and descriptions
dots doctor            # Run environment diagnostics and tool health check
dots update            # Pull latest dotfiles and refresh cache
```

### Autocomplete & Predictive IntelliSense
PowerShell uses PSReadLine 2.4.5 configured for seamless editing:
- **`InlineView` ghost text**: Suggestions appear inline as you type, without prompt jumping.
- **`F2`**: Toggle between `InlineView` and `ListView` (multi-line dropdown) instantly.
- **`RightArrow`**: Accept the entire suggested command at the end of the line.
- **`Ctrl+f`**: Accept the next word of the suggestion.
- **`Tab`**: Interactive `MenuComplete` (cycles through parameter and file candidates).
- **`Up / Down Arrow`**: History search matching what you have already typed.
- **`bun` Autocomplete**: Subcommands and dynamic npm script auto-completion from `package.json`.

### Extended Utilities (Incorporated from CTT Profile)
- `trash <path>`: Safely moves files or directories to the Windows Recycle Bin (via Shell COM API).
- `admin` (or `su`): Elevates current directory in Windows Terminal or standalone PowerShell.
- `sysinfo`: Displays system hardware, OS, kernel, uptime, and memory via `fastfetch`.
- `flushdns`: Flushes Windows DNS client resolver cache.
- `winutil`: Launches Chris Titus Tech Windows Utility.
- `df`: Shows volume and drive space (`Get-Volume`).
- `k9 <name>` / `pkill <name>`: Terminates processes by name.
- `gcom <msg>`: Shorthand for `git add . && git commit -m <msg>`.
- `lazyg <msg>`: Shorthand for `git add . && git commit -m <msg> && git push`.
- `cpy <text>` / `pst`: Clipboard copy and paste shortcuts.

#### Directory trees

Use `treeview` on Linux and WSL, or `Show-Tree` in PowerShell. Both commands
include hidden entries, place directories before files, and use indentation to
show nesting. Omit the output file to print the tree in the terminal:

```bash
treeview [DIR]
treeview [DIR] tree.txt
```

```powershell
Show-Tree -Path [PATH]
Show-Tree -Path [PATH] -OutputFile tree.txt
```

The Linux helper requires the `tree` package, which the Linux package manifests
install automatically.

### Local development

| Command | Purpose |
| --- | --- |
| `serve [DIR] [PORT]` | Start Python's HTTP server; defaults to `.` and `8000` |
| `venv [DIR]` | Create and activate a Python environment; defaults to `.venv` |
| `json FILE` | Pretty-print JSON with `jq` or PowerShell JSON support |
| `port PORT` | Show processes listening on a TCP port |
| `killport PORT` | Stop processes listening on a TCP port |
| `reload` | Reload the active shell profile |

`serve` and `venv` require Python. Linux `json` requires `jq`; Linux port
helpers use `ss`, `lsof`, or `fuser` depending on what is installed.

PowerShell history keeps up to 10,000 entries, removes duplicates, supports
history search with the arrow keys, uses menu completion on Tab, and excludes
commands containing common secret names from history.

### Git shortcuts

| Shortcut | Command |
| --- | --- |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | Recent graph log |
| `gd` | `git diff` |
| `gco` | `git checkout` |
| `gsw` | `git switch` |
| `gb` | `git branch` |
| `gcp` | `git cherry-pick` |
| `gclean` | `git clean -fd` |

`gclean` removes untracked files. Use `git clean -fdn` to preview first.

### Docker shortcuts

| Shortcut | Command |
| --- | --- |
| `dps` | `docker ps` |
| `dpa` | `docker ps -a` |
| `di` | `docker images` |
| `dlogs CONTAINER` | `docker logs -f CONTAINER` |
| `dexec CONTAINER CMD` | `docker exec -it CONTAINER CMD` |
| `dstop CONTAINER` | `docker stop CONTAINER` |
| `drm CONTAINER` | `docker rm CONTAINER` |

### Editor and monitoring tools

`micro` is the default value of `EDITOR` and the Git commit editor. Git output
uses `cat` instead of an interactive pager, so logs and diffs do not open a
second terminal buffer. The
package manifests install `micro`, `btop`, and `htop` on Linux. Windows uses
the Winget package `aristocratos.btop4win` instead of Linux `btop`/`htop`.

## Prompt

`shared/starship.toml` defines a compact three-line prompt:

1. User, host, directory, branch, and Git state.
2. Runtime, package, Docker, and project framework information.
3. Operating system and success/error status.

It detects Python, Node.js, Rust, Go, Java, Gradle, Docker, Next.js, and
Tailwind projects. It also displays command duration after two seconds and
non-zero command status.

The installer sets `STARSHIP_CONFIG` to this shared file. If Starship is not
installed, the shell continues without a custom prompt.

## Git Configuration

`shared/git/config` provides:

- `main` as the default initial branch.
- Automatic upstream setup when pushing a new branch.
- Pruned remote-tracking branches on fetch.
- Recorded conflict resolution with `rerere`.
- `zdiff3` conflict markers and histogram diffs.
- micro as the commit editor.
- The shared global ignore file.

`shared/git/ignore` covers editor files, secrets, operating-system files,
and common build, dependency, cache, and test output. It is global and does
not replace a project's own `.gitignore`.

## tmux

`shared/tmux/tmux.conf` enables mouse support, keeps 10,000 lines of history,
uses `tmux-256color`, preserves the current pane directory for new windows and
splits, and binds `prefix-r` to reload the configuration.

## Repository Standards

- `.editorconfig` defines indentation, whitespace, final-newline, and editor
  line-ending rules.
- `.gitattributes` normalizes text to LF while keeping PowerShell and Windows
  command files as CRLF.
- `.gitignore` protects this repository from secrets, editor state, and output.

## Layout

```text
.
├── install.sh
├── install-packages.sh
├── packages/
├── linux/
├── windows/
├── shared/starship.toml
├── shared/git/
├── shared/tmux/
├── .editorconfig
├── .gitattributes
└── docs/usage.md
```

## Troubleshooting

### The prompt does not appear

Install Starship, open a fresh shell, and check the configured path:

```bash
echo "$STARSHIP_CONFIG"
starship explain
```

In PowerShell:

```powershell
$env:STARSHIP_CONFIG
starship explain
```

### A package is unavailable

Use the native package name for the target manager and edit its manifest.
Linux skips unavailable entries; Winget expects exact IDs.

### The profile was already customized

The installers append marked source lines and preserve replaced targets as
`.dotfiles-backup`. Review the profile if another tool also manages startup
files.

### The editor or PATH is wrong

Edit `linux/env.sh` or `windows/env.ps1`. Linux preserves existing `EDITOR`,
`VISUAL`, `PAGER`, and `STARSHIP_CONFIG` values; PowerShell sets its defaults
when the profile loads.
