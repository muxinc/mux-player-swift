# Releasing Mux Player Swift

This guide describes the current maintainer release process for `mux-player-swift`.

## How To Use This Guide

- Humans can use the manual checklist for a concise overview of the release
  flow.
- AI agents must follow the agent-assisted runbook. Use the manual checklist as
  summary context, not as the execution procedure.

## Manual Release Checklist

1. Confirm the target version and verify the intended changes are merged to
   `main`.
2. Create `releases/vX.Y.Z` from `origin/main`, update
   `Sources/MuxPlayerSwift/PublicAPI/Version/SemanticVersion.swift`, run the
   iOS build, and open a release PR.
3. After the release PR is approved and merged, fetch `main`, verify the tag
   does not already exist, tag the merged `origin/main` commit as `vX.Y.Z`, and
   push the tag.
4. Create the GitHub release with maintainer-approved release notes.
5. Update mux.com documentation in a separate PR: always update the iOS release
   notes page, and update feature docs when the release changes customer-facing
   behavior, setup, or API usage.

## Agent-Assisted Release Runbook

Follow this section when using an AI agent to prepare or publish a new SDK
version.

### Agent Rules

- Ask for the target version before changing files. Do not infer patch, minor,
  or major unless the maintainer explicitly asks you to.
- Release branches use the `releases/vX.Y.Z` format. Do not use personal or
  agent prefixes for release branches.
- The version published to Swift Package Manager is the Git tag. The GitHub
  release is for release notes and discoverability.
- Keep release PRs small. A release PR should only update
  `SemanticVersion.swift`.
- Let maintainers collaborate on release notes. Draft notes are useful, but do
  not treat generated notes as final if a human edits them.
- For follow-up branches outside this repo, such as mux.com documentation
  updates, ask for the maintainer's team branch prefix if it is not already
  clear. Use the maintainer's normal initials-style prefix. Do not invent
  agent-specific prefixes for team-visible branches.
- If validation, merge, tag, release, or docs commands fail, stop and report the
  failure, the command that failed, and the safest next step. Do not silently
  continue past a failed release step.
- When asked to continue an interrupted release, inspect the current branch, PR,
  tag, GitHub release, and docs state first. Resume from the first incomplete
  step instead of starting over.

### Prepare The Release PR

1. Confirm the target version with the maintainer.
   - Example: `1.6.1`
   - The tag will be `v1.6.1`.

2. Verify the intended feature changes are already merged to `main`.
   - Check the relevant feature PRs.
   - Fetch the latest main and tags:
     ```sh
     git fetch origin main --tags
     ```
   - Confirm `origin/main` contains the intended release contents.

3. Check the current version state.
   ```sh
   git tag --list 'v*' --sort=-version:refname
   ```
   Confirm `Sources/MuxPlayerSwift/PublicAPI/Version/SemanticVersion.swift`
   still matches the latest release before bumping it.

4. Create a release branch from `origin/main`.
   ```sh
   git switch -c releases/vX.Y.Z origin/main
   ```
   If using a worktree, prefer a repo-local path:
   ```sh
   git worktree add <repo-local-worktrees>/release-X.Y.Z -b releases/vX.Y.Z origin/main
   ```

5. Update `Sources/MuxPlayerSwift/PublicAPI/Version/SemanticVersion.swift`.
   - Patch release: update `patch`.
   - Minor release: update `minor` and reset `patch` if needed.
   - Major release: update `major` and reset lower components if needed.

6. Validate the version bump.
   ```sh
   xcodebuild -scheme MuxPlayerSwift -destination generic/platform=iOS -derivedDataPath .build-derived-release build
   ```

7. Commit the version bump.
   ```sh
   git add Sources/MuxPlayerSwift/PublicAPI/Version/SemanticVersion.swift
   git commit -m "Version Bump"
   ```

8. Push the release branch.
   ```sh
   git push -u origin releases/vX.Y.Z
   ```

9. Open a release PR.
   - Base: `main`
   - Head: `releases/vX.Y.Z`
   - Title: `Releases/vX.Y.Z`
   - Body:
     ```md
     ## Summary
     - bump SDK semantic version from A.B.C to X.Y.Z
     ```

10. Stop until the PR is approved.

### Publish The Release

Continue only after the release PR is approved.

1. Merge the release PR.
   - If GitHub rejects merge commits, use squash merge:
     ```sh
     gh pr merge <PR_NUMBER> --squash --subject "Version Bump" --body ""
     ```

2. Fetch the merged main branch and tags.
   ```sh
   git fetch origin main --tags
   ```

3. Verify `origin/main` contains the new `SemanticVersion.swift` values.

4. Tag the merged `origin/main` commit.
   First confirm the tag does not already exist:
   ```sh
   git tag --list vX.Y.Z
   ```
   If this returns a tag, stop and ask the maintainer how to proceed.

   ```sh
   git tag vX.Y.Z origin/main
   git push origin vX.Y.Z
   ```

5. Confirm the tag points at `origin/main`.
   ```sh
   git rev-list -n 1 vX.Y.Z
   git rev-parse origin/main
   ```
   These commit SHAs must match.

6. Prepare final release notes.
   - Draft notes from the merged feature PRs and release PR.
   - Share the notes with the maintainer for review.
   - If the maintainer edits the notes in GitHub or another place, use the
     maintainer-edited version as final.

7. Create the GitHub release.
   ```sh
   gh release create vX.Y.Z \
     --target main \
     --title "vX.Y.Z" \
     --notes "<release notes>"
   ```

8. Verify the release.
   ```sh
   gh release view vX.Y.Z --json tagName,name,url,targetCommitish,publishedAt,isDraft,isPrerelease
   ```
   Confirm the release is published, not a draft, and not marked as a prerelease
   unless that was intentional.

### Update Mux Docs

After the SDK release is published, update mux.com documentation in a separate
PR.

1. Read the final GitHub release notes.
   ```sh
   gh release view vX.Y.Z --repo muxinc/mux-player-swift --json body,url,name,tagName
   ```

2. Update the Mux Player for iOS release notes page:
   `apps/web/app/docs/_guides/developer/player-releases-ios.mdx`
   - Add the new version as the current release.
   - Move the previous current release under previous releases.
   - Use the final GitHub release notes as the source.

3. Decide whether feature docs need updates.
   - Update feature docs when the release changes customer-facing behavior,
     setup, or API usage.
   - Do not add a new how-to section when behavior is automatic and there is no
     new customer-facing API. A short sentence may be enough.
   - Example from `v1.6.1`: the release added offline multitrack downloads. The
     `mux-player-ios` offline download section only needed a short note that
     offline downloads include alternate audio and subtitle tracks when present.

4. Use a team branch prefix for mux.com docs branches.
   - Ask the maintainer for their prefix if unsure.
   - Use a branch name like
     `<maintainer-initials>/player-ios-1.6.1-docs`.
   - Avoid agent-specific prefixes.

5. Validate the docs diff.
   ```sh
   git diff --check
   ```

6. Open a mux.com PR for the docs update and wait for review.

### Swift Package Manager Availability

Swift Package Manager resolves package versions from Git tags. Once `vX.Y.Z` is
pushed to GitHub, clients can resolve that version. The GitHub release does not
publish the package by itself, but it should be created for release notes.

### Common Pitfalls

- Do not tag the feature PR commit before the version bump PR is merged.
- Do not create a release tag from a local branch unless it matches
  `origin/main`.
- Do not skip asking for the target version. A feature release may still be a
  patch release.
- Do not publish generated release notes if a maintainer edited the final notes.
- Do not create team-visible branches with agent-specific prefixes.
- Do not open a replacement PR just to change a branch prefix. Rename the branch
  first when possible.
