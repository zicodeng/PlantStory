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

### Release version alignment

PlantStory uses the same two-part `major.minor` release version everywhere. Only the Git tag and development branch add a prefix:

| Release | App Store version | Git tag | Development branch | Changelog version |
| --- | ---: | ---: | ---: | ---: |
| Initial release | 1.0 | v1.0 | dev/1.0 | 1.0 |
| Feature release | 1.1 | v1.1 | dev/1.1 | 1.1 |
| Next feature release | 1.2 | v1.2 | dev/1.2 | 1.2 |

Do not append an omitted patch component such as `.0`. For App Store version `1.1`, use tag `v1.1`, branch `dev/1.1`, and changelog heading `1.1`.

The version stored in the app, entered in App Store Connect, and written in the changelog must match exactly. The Git tag adds only `v`, and the development branch adds only `dev/`.

## Release lifecycle

### 1. Develop on a focused branch

- Start from the latest `main`.
- Name feature-release branches using `dev/major.minor`, matching the target App Store version (for example, `dev/1.2`).
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
git merge --ff-only dev/1.2
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
