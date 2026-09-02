# PlantStory Privacy Policy

**Effective date: September 1, 2026**  
**Last updated: September 1, 2026**

PlantStory is a local-first plant journal created by Zike Deng. This Privacy Policy explains how PlantStory handles information when you use the iOS or iPadOS app.

## Privacy at a glance

- PlantStory does not require an account.
- Your plants, Wild Finds, photos, notes, locations, timelines, and care history are stored locally in the app's private container on your device.
- PlantStory does not include advertising, analytics, cross-app tracking, or a developer-operated server.
- AI suggestions are optional. When you request one, limited text and your OpenAI API key are sent directly from your device to OpenAI.
- Optional tips are processed by Apple through the App Store.

## Information stored on your device

PlantStory stores information you choose to add, including:

- plant and Wild Find names, species, alternate names, and notes;
- acquisition or discovery dates and user-entered locations;
- watering, fertilizing, pruning, and other care history;
- photos, photo dates, captions, and timeline events; and
- app preferences.

This information remains in PlantStory's private app container unless you choose to export it, restore it from a backup, or use an optional feature described below. PlantStory does not upload this information to a server operated by the developer.

## Photos

When you choose photos, PlantStory imports the selected images and available metadata, such as the photo creation date, into its local data files. PlantStory does not send your photos to OpenAI. Your selected photos remain on your device unless you include them in a backup that you export or share using iOS.

## Optional AI suggestions

AI suggestions are disabled unless you add your own OpenAI API key and request a suggestion. For each request, PlantStory sends the following directly from your device to OpenAI:

- your OpenAI API key, for authentication;
- the plant or Wild Find name you entered;
- existing species text, if provided; and
- your device region or locale, when relevant to a care suggestion.

PlantStory uses this information only to generate the suggestion you requested. It does not send photos, notes, care history, or your complete collection. You review each response before deciding whether to apply it.

Your OpenAI API key is stored in the iOS Keychain with device-only protection. It is not included in PlantStory backups. PlantStory requests responses with API response storage turned off (`store: false`), but OpenAI may still process or retain information as described in its own policies and the settings of your OpenAI account. Your use of this feature is also subject to OpenAI's terms and privacy practices:

- [OpenAI Privacy Policy](https://openai.com/policies/privacy-policy/)
- [OpenAI API data controls](https://platform.openai.com/docs/guides/your-data)

The developer does not receive your API key, request text, or AI responses.

## Optional tips and App Store purchases

PlantStory offers optional consumable tips that do not unlock features or content. Apple processes these purchases. PlantStory receives the product and transaction status needed to complete the purchase experience, but the developer does not receive your payment card details. Apple's handling of App Store purchase information is governed by [Apple's App Store & Privacy notice](https://www.apple.com/legal/privacy/data/en/app-store/).

## Manual backup and sharing

You may export a JSON backup containing your plants, Wild Finds, photos, notes, timelines, locations, and care history. The backup does not include your OpenAI API key or StoreKit purchase history.

You control where an exported backup is saved or shared. Any cloud storage provider, messaging app, or other service you choose may process the backup under its own privacy policy. Restoring a backup replaces the current local PlantStory collection.

## Analytics, advertising, and tracking

PlantStory does not use third-party analytics or advertising SDKs. It does not track you across apps or websites and does not sell personal information.

Apple may independently collect App Store, purchase, diagnostic, or device information under Apple's policies and your device settings. That processing is controlled by Apple, not PlantStory.

## Data retention and deletion

Local PlantStory data remains on your device until you edit or delete it, restore a different backup, or delete the app. Deleting PlantStory removes its local app-container data from that device, subject to copies that may remain in device backups or backups you exported.

You can remove your OpenAI API key at any time in **Settings -> AI Suggestions**. You can delete individual records in the app. To remove all locally stored PlantStory data, delete the app from your device and delete any backups you previously exported.

For information processed by Apple or OpenAI, use the controls and deletion procedures provided by those companies.

## Security

PlantStory relies on Apple's app sandbox and data-protection technologies to protect local files. The OpenAI API key is stored in the iOS Keychain and marked as accessible only while the device is unlocked and only on that device. Network requests to OpenAI use HTTPS through Apple's networking system. No method of storage or transmission can be guaranteed to be completely secure.

## Children's privacy

PlantStory is not designed to collect personal information from children. It has no account, social, messaging, or advertising features. If a child uses the optional OpenAI feature, a parent or guardian should supervise the use of the OpenAI account and review OpenAI's applicable age requirements and policies.

## International processing

Local information remains on your device. If you use AI suggestions or an Apple purchase, OpenAI or Apple may process information in countries other than your own according to their respective policies.

## Changes to this policy

This policy may be updated if PlantStory's features or privacy practices change. Material changes will be reflected by updating the date at the top of this document and, when appropriate, through the app or its App Store listing.

## Contact

For privacy questions or requests, contact the developer by opening an issue in the [PlantStory GitHub repository](https://github.com/zicodeng/PlantStory/issues). Please do not include API keys, private photos, backups, or other sensitive information in a public issue.
