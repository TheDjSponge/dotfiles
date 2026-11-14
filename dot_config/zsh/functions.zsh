# Sync dotfiles: add all changes, scan them for secrets, commit, and push.
# The dotfiles repo is PUBLIC -- gitleaks blocks the commit if anything that
# looks like a key/token is staged. False positive? Add its fingerprint
# (printed by gitleaks) to .gitleaksignore in the chezmoi source dir.
czsync() {
  local message="${1:-Manual sync: $(date +'%Y-%m-%d %H:%M:%S')}"
  local src; src="$(chezmoi source-path)" || return 1

  if ! command -v gitleaks &>/dev/null; then
    echo "czsync: gitleaks not installed -- refusing to push to a public repo unscanned." >&2
    return 1
  fi

  chezmoi git -- add . || return 1

  if chezmoi git -- diff --cached --quiet; then
    echo "czsync: nothing to commit."
    return 0
  fi

  if ! gitleaks git --staged --redact --no-banner "$src"; then
    chezmoi git -- reset -q
    echo "czsync: possible secret found (see above) -- changes unstaged, nothing committed." >&2
    return 1
  fi

  chezmoi git -- commit -m "$message" && chezmoi git -- push
}
