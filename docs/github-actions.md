# Colin OS GitHub Actions Strategy

## Trigger Model

The Colin OS ISO workflow is triggered on:

- Git tag push matching `v*`
- manual `workflow_dispatch`

This matches the current release policy: official ISO releases are created when a version tag is created.

## Workflow File

- [build-iso.yml](/D:/Colin-OS/.github/workflows/build-iso.yml)

## Runner Choice

The workflow uses `ubuntu-24.04`.

This is intentional because Colin OS itself targets Ubuntu 24.04 LTS, and GitHub currently provides `ubuntu-24.04` as a standard hosted runner label. I am inferring that aligning the runner baseline with the target release will reduce host-tool mismatch risk.

## Authentication

The workflow grants:

- `contents: write`

This is required so the job can publish release assets with `GITHUB_TOKEN`.

## Release Behavior

On a tag build, the workflow:

1. checks out the repository
2. installs build dependencies
3. runs the same top-level build script used locally
4. uploads ISO and logs as workflow artifacts
5. creates or updates the GitHub Release for the tag
6. uploads the ISO and checksum files to that release

## Action Version Notes

As of July 22, 2026:

- `actions/checkout` latest release is `v7.0.1`
- `actions/upload-artifact` latest release is `v7.0.1`

The workflow therefore uses:

- `actions/checkout@v6`
- `actions/upload-artifact@v7`

Reason:

- `actions/upload-artifact@v7` matches the latest major release.
- `actions/checkout@v6` is kept intentionally instead of jumping to `v7` immediately, because `v6.1.0` and `v7.0.1` were both released on July 20, 2026 and `v6` remains a conservative stable pin for a first workflow revision. This is an implementation choice, not a claim that `v6` is the newest major.

## Current Limitations

- The workflow does not yet produce an installable Calamares-based image because installer integration is still a placeholder.
- The workflow assumes Ubuntu repository availability from the GitHub hosted runner.
- The workflow has not been executed from this environment yet, so it is structurally prepared but not runtime-validated.
