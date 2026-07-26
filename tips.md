# Codex Tips

## User Requirements

- For GitHub Actions runs, do not use `gh run watch`; it floods the context window.
- Preferred workflow polling pattern:
  - trigger the run
  - `sleep` 5 minutes
  - check status once
  - if still running, `sleep` another 5 minutes and check once again
- When discussing run history or failures, use concrete dates and times instead of only relative wording.
- Keep local-only files out of commits unless explicitly requested:
  - `.claude/`
  - `memory.md`

## Terminal / Execution Pitfalls

- In this PowerShell environment, `&&` is not a valid command separator. Run commands separately or use PowerShell-native sequencing.
- Avoid noisy long-running status commands when a single delayed status check will do.
- Prefer concise log extraction with targeted `rg` filters over dumping full workflow logs.
- When a package is unavailable in the current Ubuntu release, verify pool/archive availability before adding it to `apt-get install`.
