# Releasing PlantStory

This document describes the release workflow for PlantStory. It keeps the code on `main`, the App Store build, the changelog, and Git tags aligned.

## Versioning rules

PlantStory uses two version values:

- **Version** (`MARKETING_VERSION`) is the customer-facing release number, such as `1.1`.
- **Build** (`CURRENT_PROJECT_VERSION`) identifies an uploaded build of that version, such as `1` or `2`.

Start each new App Store version at build `1`. If another build of the same version must be uploaded, increment only the build number:

| Situation | Version | Build |
| --- | ---: | ---: |
| First submission for a new release | 1.1 | 1 |
| Review fix or replacement upload | 1.1 | 2 |
| Next feature release | 1.2 | 1 |

Keep the app and widget targets on the same version and build.

### App Store versions and Git tags

PlantStory keeps Git tags aligned exactly with the customer-facing version in App Store Connect. `CHANGELOG.md` uses the normalized semantic version:

| Release | App Store version | Git tag | Changelog version |
| --- | ---: | ---: | ---: |
| Initial release | 1.0 | v1.0 | 1.0.0 |
| Feature release | 1.1 | v1.1 | 1.1.0 |
| Patch release | 1.1.1 | v1.1.1 | 1.1.1 |
| Next feature release | 1.2 | v1.2 | 1.2.0 |

The Git tag is the App Store version with a `v` prefix. For a two-part App Store feature release such as `1.1`, use `v1.1`; do not append `.0`. Use a third component only for an actual App Store patch release, such as `1.1.1` and `v1.1.1`.

The version stored in the app, entered in App Store Connect, and recorded in the Git tag must match each other apart from the tag's `v` prefix. The changelog continues to use a full three-part semantic version.

## Release lifecycle

### 1. Develop on a focused branch

- Start from the latest `main`.
- Name feature-release branches using `dev/major.minor.patch`, where the version is the target semantic app version (for example, `dev/1.2.0`).
- Use one branch for one coherent feature or release.
- Add notable user-facing changes to the upcoming `Unreleased` section of `CHANGELOG.md`.
- Keep unrelated local files, generated artifacts, and shared-scheme overrides out of commits.

### 2. Prepare the release candidate

When the release is feature-complete:

1. Set `MARKETING_VERSION` to the new App Store version.
2. Reset `CURRENT_PROJECT_VERSION` to `1` for both the app and widget targets.
3. Leave the changelog entry marked `Unreleased`; the public release date is not known yet.
4. Perform a normally signed build, install, and launch.
5. Run `git diff --check`, review the final diff, and commit the release version changes.
6. Confirm the working tree contains no unintended changes before archiving.

### 3. Archive and submit

- Archive `PlantStory.xcodeproj` with the `PlantStory` scheme and normal signing.
- Store archives under `~/Library/Developer/Xcode/Archives/YYYY-MM-DD/` so they appear in Xcode Organizer.
- Verify the archived app and widget contain the intended version and build.
- Upload the archive, complete the App Store metadata, and submit it to App Review.
- Promotional Text should describe the app's current appeal. What's New should describe changes specific to this release.
- Do not mention unavailable AI or OpenAI features in public metadata or screenshots used for the China mainland storefront.

### 4. Merge after submission

Once the exact build has been submitted to App Review, merge its branch into `main`. Do not wait for approval.

```sh
git switch main
git pull --ff-only origin main
git merge --ff-only dev/1.2.0
git push origin main
```

Keep the feature branch until review is complete. At this point:

- `main` is the source of truth for the submitted build.
- `CHANGELOG.md` still says `Unreleased`.
- No final release tag exists yet.

### 5. Handle review fixes

If App Review requires a binary change:

1. Create a focused fix branch from `main`.
2. Keep the same marketing version.
3. Increment the build number, for example from `1.1 (1)` to `1.1 (2)`, for both app and widget targets.
4. Build, archive, upload, and resubmit.
5. Merge the fix into `main` after submitting it.

Metadata-only corrections do not require a new archive unless App Store Connect specifically requires one.

### 6. Finalize after distribution

Wait until the version is approved and distributed on the App Store before finalizing the release record:

1. Replace `Unreleased` in `CHANGELOG.md` with the actual release date in `YYYY-MM-DD` format.
2. Commit that changelog update on `main`.
3. Create an annotated tag by adding a `v` prefix to the App Store version, such as `v1.1`.
4. Push `main` and the tag.

```sh
git tag -a v1.1 -m "PlantStory 1.1"
git push origin main v1.1
```

Create the tag only after the version is distributed. This makes the final tag clearly mean "publicly released," rather than merely submitted or approved.

### 7. Clean up

After confirming the release and tag on the remote:

- Keep the Xcode archive for symbolication and future reference.
- Optionally create a GitHub release from the version tag.
- Delete the completed feature and review-fix branches when they are no longer needed.
- Start the next release branch from the updated `main`.

## Quick reference

| App Store state | Merge to `main`? | Date the changelog? | Create final tag? |
| --- | --- | --- | --- |
| In development | No | No | No |
| Submitted for review | Yes | No | No |
| Rejected, fix required | Merge each submitted fix | No | No |
| Approved but not distributed | Already merged | No | No |
| Ready for Distribution / live | Already merged | Yes | Yes |
