# AGENTS.md — Rules for AI Agents Working in This Repo

You are operating in Aaron Lauer's chezmoi dotfiles repo
(`git@github.com:alauer/dotfiles.git`), which configures a fleet of Omarchy
(Hyprland/Arch) machines: `tachikoma-1` (desktop), `tachikoma-2` (laptop), and
future hosts. Read `docs/SDD-portable-baseline.md` before any structural change


## Hard safety rules

1. **NEVER run `chezmoi apply`** (with or without `--force`) on a live machine
   without Aaron's explicit approval in that session. It overwrites real config.
   Safe alternatives: `chezmoi diff`, `chezmoi cat <target>`,
   `chezmoi execute-template`, `chezmoi managed`, `chezmoi doctor`.
2. **NEVER run destructive git operations** (rebase of pushed history, force-push,
   reset --hard, branch delete) without approval.
3. **The pre-commit hook is doctrine, not an obstacle.** It blocks commits when
   `chezmoi diff` shows drift. Fix the drift (re-add, host-gate, or ignore with
   reason) — do not bypass with `--no-verify` and do not extend its exclusion list.
   It lives at `.githooks/pre-commit` and runs ONLY if `core.hooksPath` points there;
   an unwired hook fails silently. Verify with `git config --get core.hooksPath` and set
   it on any fresh clone: `git config core.hooksPath .githooks`.
4. **The repo is PUBLIC.** Never commit secrets, tokens, internal IPs, tailnet
   hostnames-with-credentials, or private keys. Secrets go through age
   (`chezmoi add --encrypt` → `encrypted_*.age`) or the per-host `~/.env` pattern
   (never in repo). If unsure whether something is secret: it is.
5. **`~/.hermes` never enters this repo.** The machine-intelligence layer
   (identity, skills, memories, agent config) is explicitly out of scope — it is
   listed in `.chezmoiignore`. Never `chezmoi add` anything under it.
6. **Scope is classic dotfiles only.** User dotfiles and environment preferences
   under `$HOME`. System files outside `$HOME` (udev rules, /usr/local/bin, NM
   dispatcher) are hand-managed per host and must not be added here.

## How this repo works (contract)

- **Source of truth direction:** for shared config, the repo is the source of
  truth and `$HOME` is target state. When the live config is *newer/better*, sync
  it in with `chezmoi re-add <path>` or `chezmoi add <path>` — don't hand-copy.
- **Naming conventions are chezmoi's:** `dot_` → `.`, `private_` → mode 0600,
  `executable_` → +x, `symlink_` → symlink, `.tmpl` → Go template rendered with
  chezmoi data. Don't "fix" these names; they are semantics.
- **Platform differences, not host differences.** Machines differ by *platform*
  (distro family, Omarchy or not, laptop or not, CPU vendor), never by hostname. Gate with
  the partials in `.chezmoitemplates/` (`is-arch`, `is-omarchy`, `is-laptop`, `is-intel`):
  `{{ if includeTemplate "is-laptop" . }}`. Look and feel belongs to the Omarchy theme, not
  this repo. No hostname-suffixed copies, no branches.
- **Packages and plugins are data:** `.chezmoidata/packages.yaml`, `omarchy.yaml`. The
  install scripts are inert unless `CHEZMOI_INSTALL=1`; never set it on a live machine.
- **Runtime state is never tracked.** If you find caches, logs, DBs, session
  history, browser profiles, or agent runtime dirs in a diff, extend
  `.chezmoiignore` with a one-line comment explaining why.

## Workflow for common tasks

- **Changing a shared config:** edit the source file (`.tmpl` if it needs data),
  verify with `chezmoi diff` (should show exactly your intended change and nothing
  else), commit.
- **Adding a new file from `$HOME`:** `chezmoi add <path>`; add `--encrypt` for
  secrets; convert to `.tmpl` + host data if any line is host-specific.
- **Adding a host-specific file:** gate it in templated `.chezmoiignore` or via
  `{{ if }}` in the `.tmpl`; use the platform partials above.
- **Triaging drift** (`chezmoi diff` non-empty when you didn't cause it):
  classify each file per SDD §5 — stale repo (re-add), legitimate host difference
  (platform-gate), transient (ignore), hazard (delete + gate). Report findings before
  acting on anything classified "hazard".
- **Testing render for another host:** `chezmoi execute-template
  ` for data-only checks, or the devcontainer; never by
  temporarily editing `.chezmoi.yaml` on a live machine.

## Verification standard

Done means: `chezmoi diff` shows only intended changes; `chezmoi doctor` clean;
templates render under BOTH gate values (empty a partial temporarily in a scratch copy, never on the live source without restoring); pre-commit hook
passes without bypass. Report actual command output, not intent.

## Escalation

If a task requires `chezmoi apply`, deleting tracked files that a live host may
depend on, or any change to encryption recipients: stop and ask Aaron. If you are ~70% sure a requested change is
dangerous or identity-erasing, refuse and escalate — that is doctrine in this
household, not insubordination.
