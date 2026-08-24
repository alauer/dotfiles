# AGENTS.md

## Scope

This repository is the reproducible chezmoi source for user-level configuration and desktop assets across supported machines. Treat it as a public source repository unless the remote visibility is verified otherwise.

## Instruction Order

1. Read this file before inspecting or changing repository content.
2. Follow explicit user instructions and the approved phase contract.
3. When instructions conflict, obey the stricter safety boundary.
4. Read-only access is not permission to expand scope. Stop and report when required evidence or commands fall outside the approved phase.

## Operating Model

- Work in one narrow phase at a time.
- State the exact goal, paths, permitted mutations, exclusions, checks, and stop point before mutation.
- Plan first. Mutation requires explicit approval of the named phase.
- Never infer approval for a later phase from approval of an earlier phase.
- Prefer an isolated feature branch and Git worktree for mutations.
- Keep the canonical checkout clean and on its default branch.
- Never commit directly to the default branch.
- Staging, committing, pushing, applying, installing, and restarting are separate approval gates unless the user explicitly approves them together.
- Stop on unexpected repository state, managed-path conflicts, unexplained sensitive content, or scope drift. Do not improvise around a failed gate.

## Chezmoi Semantics

- The repository contains chezmoi source state, not ordinary destination paths. Verify source-to-target mapping before adding or renaming files.
- Use the repository or worktree as chezmoi's source with the correct `--source` / `-S` option. Do not confuse a source path with a destination path.
- Never point chezmoi's destination at another repository or worktree.
- Never run `chezmoi apply`, `init --apply`, `update`, `re-add`, `merge`, `import`, or `--force` without explicit approval.
- Treat every `run_*` source file as executable during an eligible `chezmoi apply`. Review rendered content and execution conditions before approval.
- Validate templates and mappings in an isolated temporary destination when safe scoping is proven. Do not render or apply unrelated targets merely to test one change.
- An empty destination directory may require a documented `.keep` source placeholder. Do not add placeholders without confirming why the directory must exist.

## Secrets and Privacy

- Do not add plaintext passwords, private keys, API tokens, session cookies, recovery material, credential-bearing URLs, or password-store exports.
- Do not inspect unrelated SSH, GPG, age, browser-profile, password-store, message, photo, video, or personal-document content.
- Existing encrypted artifacts are not permission to inspect, decrypt, copy, or modify them.
- If a destination does not require a secret, the source must not contain it, encrypted or otherwise.
- Before commit, scan only the intended change for secrets, private network addresses, personal absolute paths, and credential-bearing URLs. Redact suspected values in reports.
- Public identifiers and template variables must be intentional and documented. Never commit machine-specific `/home/<user>` paths when a portable mapping is possible.

## Ownership and Licensing

- Verify redistribution rights before adding third-party themes, artwork, fonts, icons, wallpapers, or generated media to a public repository.
- Do not vendor upstream packages when a documented reproducible installation path is sufficient, unless vendoring is explicitly approved.
- Proprietary, private-use, reference-based, or rights-unclear artwork is excluded by default until redistribution permission is proven.
- Preserve applicable upstream license and attribution metadata.

## Desktop Safety

- Do not capture whole generated desktop-state files by default.
- KDE and Plasma configuration changes must name exact files, groups, and keys.
- `~/.config/plasma-org.kde.plasma.desktop-appletsrc` and equivalent layout/state files are protected. Do not modify or import them without explicit approval.
- Do not change active themes, layouts, wallpapers, widgets, services, packages, login state, or desktop processes during source ingestion.
- Do not call `kwriteconfig*`, `qdbus*`, `systemctl`, desktop reload/reconfigure commands, logout, reboot, or package managers without explicit approval.
- Keep desktop-environment-specific assets isolated so unsupported hosts can safely ignore them.

## Git Discipline

- Before mutation, verify branch, HEAD, tracking state, worktree cleanliness, and remote configuration.
- Never use broad staging commands for a scoped commit. Stage exact approved paths.
- Keep logically distinct work in separate commits. Assets, operating doctrine, activation logic, installers, and unrelated cleanup should not be mixed.
- Do not rewrite, squash, rebase, force-push, delete branches, or remove worktrees without explicit approval.
- Do not use broad rollback commands such as `chezmoi apply --force` or destructive Git resets as a substitute for a target-scoped rollback.
- Rollback must name the exact commit, source paths, destination paths, and executable scripts affected.

## Required Validation

Run checks appropriate to the intended change before commit:

1. Exact changed-file manifest and package-boundary check.
2. Source-to-live or source-to-reference byte comparison, with every intentional transformation explained.
3. JSON, XML, SVG/SVGZ, shell, template, and language-specific syntax validation where applicable.
4. Symlink inventory; reject broken links or links escaping approved package roots.
5. Secret, credential, private-address, and personal-path scan of intended changes.
6. License and attribution review for redistributed assets.
7. `git diff --check` with no newly introduced errors.
8. Review unstaged and staged diffs separately.
9. Confirm unrelated tracked files, canonical checkout, live destinations, packages, services, and desktop state are unchanged.
10. Run repository tests or scoped deterministic checks when present.

A skipped check must be reported with the exact reason. Do not describe a skipped check as passed.

## Commit and Push Gate

Before committing:

- Show the staged manifest and staged diff/stat.
- Confirm no unrelated files are staged.
- Confirm validation results and known limitations.
- Use a commit message that describes one atomic scope.

Before pushing:

- Re-run the blocking checks against committed `HEAD`.
- Verify branch and remote destination.
- Push only the approved feature branch.
- Confirm the remote branch resolves to the expected commit.

## Reporting

Report concisely:

- inspected state,
- exact changes made,
- validation executed and its real output,
- skipped or unavailable checks,
- remaining risks or decisions,
- Git branch, commit, and push state,
- whether any live destination or service changed.

Never substitute plausible output for a command or test that was not actually run.