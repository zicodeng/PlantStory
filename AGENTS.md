# PlantStory Repository Instructions

## Start with the existing app

- PlantStory is a SwiftUI iOS app for plant care tracking, beginner education, and optional AI assistance.
- Always inspect the current branch and `git status`. For narrowly scoped requests, inspect only directly relevant files. Read `CHANGELOG.md` or Git history only when the existing feature scope is unclear, and do not assume a feature is missing based only on the task description.
- Search large files with targeted `rg` queries. Do not print entire string catalogs, Xcode project files, diffs, or build logs unless necessary to diagnose a failure.
- Treat existing uncommitted changes as user work. Preserve them and do not reset, overwrite, stage, or commit them unless they are explicitly part of the request.

## Product principles

- Keep the experience approachable for beginner plant owners. Prefer plain language, progressive disclosure, and visual explanations over botanical jargon or dense paragraphs.
- Preserve PlantStory's local-first privacy model. Features should work without an account or server whenever practical, and should not upload user data without clear consent.
- Keep AI optional, review-before-apply, and powered by the user's own securely stored API key. Do not make core app functionality depend on AI.
- Preserve the China-mainland storefront restrictions in `PlantStoryApp.swift`. When preparing China distribution, remove unavailable AI references from localized public metadata and screenshots as well as the app UI.

## UI and localization

- Match the established PlantStory visual language and reuse existing components, colors, spacing, icons, and navigation patterns where possible.
- Add every user-facing string to `PlantStory/Localizable.xcstrings` with both English and Simplified Chinese support.
- For localization changes, ensure English and Simplified Chinese entries exist. The user handles visual language verification unless explicitly requested.
- Keep accessibility labels, hints, Dynamic Type behavior, contrast, and tap-target sizes in mind for new controls.

## Build and verification

- Use `PlantStory.xcodeproj` and the `PlantStory` scheme.
- After completing a coherent batch of app code, UI, asset, or localization changes, use XcodeBuildMCP to perform a normally signed simulator build, install, and launch.
- Do not capture screenshots, inspect the simulator UI, navigate through the app, or perform visual verification unless the user explicitly requests it. The user will manually verify the refreshed app.
- Do not pass `CODE_SIGNING_ALLOWED=NO`; PlantStory's Keychain-backed API-key flow requires normal signing.
- Before handing work back, run `git diff --check`, review the final diff, and report the build result and any explicitly requested verification.

## Git and releases

- Follow the branch naming and release workflow in `RELEASING.md`; feature-release branches must use `dev/major.minor.patch`.
- Do not commit or push unless the user explicitly asks.
- Before committing, inspect `git status` and stage only the files that belong to the requested change. Do not include generated builds, archives, or unrelated shared-scheme changes.
- Update `CHANGELOG.md` for notable user-facing features and bug fixes.
- Preserve `MARKETING_VERSION` when the user requests a build-only release; increment only `CURRENT_PROJECT_VERSION`.
- Put release archives in `~/Library/Developer/Xcode/Archives/YYYY-MM-DD/` so Xcode Organizer can find them.
