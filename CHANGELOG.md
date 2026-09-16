# Changelog

All notable user-facing changes to PlantStory are recorded here under **New features** and **Bug fixes**. These entries can also be used to prepare App Store “What’s New” notes.

## [1.2] - Unreleased

### New features

- Expanded the Houseplant Family Finder to 100 source-verified plants across its ten featured families, including supported alternate and former scientific names.
- Added watering reminder dates to the care calendar, with a distinct month marker and filters for fertilizing, pruning, and watering due.

## [1.1] - 2026-09-15

### New features

- Added **Plant Wiki**, a new beginner-friendly learning tab with visual guides for plant anatomy, common problems, leaf shapes and patterns, common pests, roots and repotting, watering, light, new growth and life stages, propagation, and plant families and taxonomy.
- Added interactive plant illustrations and visual comparisons that make unfamiliar plant parts, symptoms, light levels, pests, roots, and propagation methods easier to recognize.
- Added an interactive root close-up covering the root crown, structural and lateral roots, fine roots, root hairs, and growing tips.
- Added an interactive stem and node close-up covering growth points, leaf attachments, aerial roots, and pruning clues.
- Added an offline **Houseplant Family Finder** that can search common names, scientific names, alternate names, genera, and families without uploading search data.
- Added local watering reminders with a customizable schedule and time for each plant, reminder status on garden cards, and a central reminder dashboard in Settings.
- Added seasonal watering schedules with separate spring, summer, fall, and winter intervals and one shared active-season setting for the whole garden.
- Expanded My Garden AI suggestions with structured care guides, seasonal watering recommendations, plant taxonomy, and an option to create a reminder from the suggested intervals.
- Expanded Wild Finds AI suggestions with a taxonomy-first layout and structured field-guide details covering appearance, identifying features, growth habit, flowers and fruit, habitat, native range, and lookalikes.
- Added complete English and Simplified Chinese localization for the new reminders, AI guidance, and Plant Wiki content.
- Added a medium Home Screen widget that shows up to three due watering reminders and opens the selected plant.

### Bug fixes

- Fixed Plant Wiki anatomy cards not opening their interactive lessons.
- Made anatomy part sheets fit their content and added more breathing room below the final explanation.
- Kept garden cards the same height by showing a placeholder when a plant has no watering reminder.
- Made overdue watering reminders easier to notice with a distinct warning color.
- Fixed Plant Wiki titles and the Wild Finds discovery count not updating immediately after changing the app language.
- Fixed missing Chinese Plant Wiki translations and removed English pronunciation hints from Chinese plant-part lessons.
- Refined seasonal controls with distinct icons and colors, more consistent spacing, and no unexpected animation when switching guide tabs.

## [1.0] - 2026-09-14 (Initial release)

### New features

- Created **My Garden**, a home collection for organizing plants by reusable rooms and locations.
- Added plant profiles with common, alternate, and scientific names, acquisition dates, notes, photos, and days-raised tracking.
- Added search and sorting by name, acquisition date, last watered date, and last fertilized date.
- Added watering and fertilizing history with quick care actions and support for removing accidental entries.
- Added seasonal fertilizing and pruning schedules with a monthly care calendar.
- Added chronological life timelines with dated photos, notes, and event types such as new growth, blooming, repotting, pruning, treatment, and coming home.
- Added memorial handling for plants that have died while preserving their timelines and days-raised totals.
- Created **Wild Finds**, a separate collection for recording plants discovered outdoors, including names, species, dates, locations, notes, photos, search, and timelines.
- Added optional AI suggestions for plant identity, alternate names, seasonal care months, care notes, and Wild Find descriptions.
- Added review-before-apply controls for every AI suggestion.
- Added complete English and Simplified Chinese localization with an in-app language selector.
- Added manual JSON backup and restore for plants, Wild Finds, photos, notes, timelines, locations, and care history.
- Added optional consumable tips to support development without locking any app features.
- Added links to project information, source code, support, credits, and privacy details.
- Added local-first storage with no account, cloud database, advertising, analytics, or cross-app tracking.
- Added secure, device-only Keychain storage for the optional user-provided OpenAI API key.

### Bug fixes

- Removed the alpha channel from the app icon for App Store compatibility.
- Prevented unavailable tip products from appearing actionable and added an informative fallback display for support tiers.
- Disabled AI-assisted features and removed OpenAI references when the app is downloaded from the China mainland storefront.
