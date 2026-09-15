# PlantStory

<p align="center">
  <img src="PlantStory/Assets.xcassets/AppIcon.appiconset/PlantStory-AppIcon.png" width="128" alt="PlantStory app icon">
</p>

<p align="center">
  A free, open-source, local-first iOS journal for the plants you raise and the plants you meet outside.
</p>

PlantStory helps you remember the life of each plant—not just its care schedule. Keep photo timelines, record everyday care, schedule seasonal watering reminders, learn with beginner-friendly visual guides, and save wild discoveries in a private collection that stays on your iPhone.

## Features

### My Garden

- Add and edit plants with a name, alternate name, species, acquisition date, notes, and photos.
- See how many days you have raised each plant.
- Build a chronological life timeline with dated photos, notes, and optional event tags for repotting, pruning, fertilizing, blooming, new growth, pests, treatment, coming home, death, or a custom event. Untagged photos remain “A new moment.”
- Mark a plant’s death from its timeline to give its garden card a muted “In memory” treatment while preserving its days-raised count.
- Automatically use a photo's creation date when that metadata is available.
- Record watering and fertilizing events, review recent history, and remove accidental entries.
- Choose the best fertilizing and pruning months for each plant.
- View seasonal care tasks in a garden calendar.
- Create local watering reminders with a time and either one year-round interval or separate spring, summer, fall, and winter intervals.
- See upcoming and overdue reminders on garden cards and manage every configured reminder from Settings.
- Mark a plant as watered or ask to be reminded tomorrow directly from its notification.
- Assign plants to locations such as rooms, balconies, or gardens, reuse existing location choices, and browse the home collection grouped by location.
- Search your collection and sort it by name, acquisition date, last watered, or last fertilized in ascending or descending order.

### Plant Wiki

- Learn plant care through visual, interactive guides designed for beginners.
- Explore plant anatomy, common symptoms, leaf shapes and patterns, pests, roots and repotting, watering, indoor light, new growth and life stages, propagation, and plant families and taxonomy.
- Open interactive close-ups of roots, stems, nodes, leaves, flowers, and other plant structures.
- Use the offline Houseplant Family Finder to search common names, scientific names, alternate names, genera, and families without uploading search data.

### Wild Finds

- Save plants discovered in parks, on trails, and while traveling.
- Record names, species, discovery dates, locations, notes, and photo timelines.
- Search your saved discoveries.
- Keep wild observations separate from the plants you care for at home.

### Watering widget

- Add the medium PlantStory Home Screen widget to see up to three plants that are due for watering.
- Tap a reminder in the widget to open that plant directly in PlantStory.
- Keep widget and reminder data on the device through PlantStory's private app group.

### Optional AI suggestions

- Bring your own OpenAI API key to suggest plant identity, alternate names, taxonomy, care notes, seasonal care months, and seasonal watering intervals.
- Review a structured care guide and optionally turn suggested watering intervals into a local reminder.
- Generate taxonomy and field-guide details for Wild Finds, including appearance, identifying features, growth habit, flowers and fruit, habitat, native range, and lookalikes.
- Review every suggestion before applying it.
- AI is completely optional; all core plant-tracking features work without it.
- The API key is stored in the iOS Keychain and requests are billed directly to the user's OpenAI API account.
- AI features are unavailable when PlantStory is downloaded from the China mainland App Store; the journal, reminders, Plant Wiki, backup, and other local features remain available.

### Language support

- Use PlantStory in English or Simplified Chinese.
- Follow the iPhone language automatically or choose a language inside the app.

### Privacy and storage

- No PlantStory account is required.
- No cloud database or PlantStory server is used.
- Plants, photos, notes, care histories, and reminder schedules remain in the app's private local storage.
- The watering widget receives only the small on-device snapshot it needs through PlantStory's private app group.
- Plant data is stored in `Library/Application Support/PlantStory/plants.json`.
- Wild Finds are stored in `Library/Application Support/PlantStory/wild-finds.json`.
- Photos and their dates and notes are encoded in those private files.
- Export a versioned JSON backup from **Settings → Storage & Data** and restore it on another iPhone. The backup includes both collections and their photos but excludes the OpenAI API key and StoreKit purchase history.
- When AI is requested, limited text is sent directly to OpenAI; photos and care history are not sent.

Deleting PlantStory deletes its local data from that iPhone. Before deleting it, export a manual backup or transfer the device with Apple Quick Start, iCloud Backup, or a Finder/Apple Devices backup. The OpenAI API key may need to be entered again.

## Manual backup and restore

Open **Settings → Storage & Data** to manage portable backups.

### Create a backup

1. Tap **Export Backup**.
2. Save the generated JSON file to Files, iCloud Drive, or another location you control.
3. Keep the file until you have confirmed the data is available on the destination device.

The backup contains My Garden, Wild Finds, photos, notes, timeline events, locations, care histories, and watering reminder settings. Because photos are embedded in the JSON file, backups with many photos can be large. OpenAI API keys and StoreKit purchase history are not included.

### Restore a backup

1. Tap **Restore from Backup** and select a PlantStory JSON backup.
2. Review the backup date and the number of plants and Wild Finds shown in the confirmation.
3. Confirm **Restore**.

Restore replaces the current My Garden and Wild Finds collections; it does not merge them. Export the current collection first if you may need it later.

## Download and install

Choose a published release for a stable source snapshot, or use the `main` branch for the latest development version. See the changelog for release notes and current development details.

- [View and download the latest published release](https://github.com/zicodeng/PlantStory/releases/latest)
- [Download the current development source](https://github.com/zicodeng/PlantStory/archive/refs/heads/main.zip)
- [Read the changelog](CHANGELOG.md)

### Requirements

- macOS with Xcode
- iOS 17.0 or later, or an iOS Simulator
- An Apple ID added to Xcode when installing on a physical iPhone
- Notification permission only if you enable watering reminders
- An OpenAI API key only if you choose to enable AI suggestions

### Build from source

```bash
git clone https://github.com/zicodeng/PlantStory.git
cd PlantStory
open PlantStory.xcodeproj
```

In Xcode:

1. Select the **PlantStory** target.
2. Open **Signing & Capabilities** and choose your development team for the app and widget targets.
3. If Xcode reports that a bundle identifier is unavailable, replace `com.zicodeng.PlantStory` and `com.zicodeng.PlantStory.Widget` with unique identifiers.
4. Update the shared App Group capability to an identifier available to your development team.
5. Choose an iOS Simulator or your paired iPhone as the run destination.
6. Press **Run** (`⌘R`).

Installing with a free Apple ID is suitable for personal development but may require periodic reinstalling. App Store or TestFlight distribution requires Apple Developer Program membership.

## AI setup

AI suggestions are disabled by default.

1. Create an API key in your OpenAI account.
2. In PlantStory, open **Settings → AI Suggestions**.
3. Enter the key, acknowledge that requests use your API credits, and save it.
4. Open a plant or Wild Find editor and tap **Suggest with AI**.

PlantStory currently uses `gpt-5.4-nano` through the OpenAI Responses API with response storage disabled. Model availability and API pricing can change; consult OpenAI's current documentation before relying on a particular cost.

AI setup is not shown when the app is downloaded from the China mainland App Store.

## Support

For help, troubleshooting, feedback, or feature requests, visit [PlantStory Support](https://zicodeng.github.io/PlantStory/support/). You can also [open a GitHub issue](https://github.com/zicodeng/PlantStory/issues/new).

## Contributing

Ideas, bug reports, design improvements, and code contributions are welcome.

1. [Open an issue](https://github.com/zicodeng/PlantStory/issues/new) to describe a bug or propose an improvement.
2. Fork the repository.
3. Create a focused branch:

   ```bash
   git checkout -b feature/your-idea
   ```

4. Make your changes and verify that the app builds and runs on an iOS 17+ Simulator.
5. Commit with a clear message and push your branch.
6. Open a pull request explaining what changed and, for UI changes, include before-and-after screenshots.

Please keep pull requests focused, preserve the local-first privacy model, and never commit API keys, signing credentials, or personal data.

## Support the project

If PlantStory is useful to you, [star the project on GitHub](https://github.com/zicodeng/PlantStory) to help other plant lovers discover it.

## Credits

PlantStory is vibe-coded with love by [Zico](https://github.com/zicodeng). The complete source is available to explore, customize, and grow into your own plant companion.

## License

PlantStory is available under the [MIT License](LICENSE).
