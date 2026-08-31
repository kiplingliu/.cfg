set -euo pipefail

log_error() { printf '[ERROR] %s\n' "$*" >&2; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

wsl_config_dir="$SCRIPT_DIR/wsl"
for f in "$wsl_config_dir"/.*; do
    ln -fs "$f" "$HOME/${f#"$wsl_config_dir/"}"
done

pwsh.exe "$(wslpath -w "$SCRIPT_DIR/Install-WslGitConfig.ps1")"
