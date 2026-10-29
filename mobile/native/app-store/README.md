# App Store artwork

The shipping app icon lives in
`../ios/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
It is an opaque, square 1024 × 1024 PNG based on Glossia's white mark and
orange-to-magenta brand gradient. iOS applies its own icon mask.

## English screenshots

`screenshots/en-US/` contains five ordered screenshots for each display size:

| Directory | Dimensions | Display |
| --- | --- | --- |
| `iphone` | 1320 × 2868 | 6.9-inch iPhone |
| `iphone-medium` | 1206 × 2622 | 6.3-inch iPhone |
| `ipad` | 2064 × 2752 | 13-inch iPad |

The screenshots show production SwiftUI views using the isolated
`GlossiaIOSPreview` demo fixtures, not generated app interfaces. The marketing
frame uses Glossia's logo, Inter and Source Serif typography, and cream,
violet and coral colors. The medium iPhone set is proportionally resized from
the large iPhone set; iPad views were captured separately.

| File | Preview scenario |
| --- | --- |
| `01-language-team.png` | `empty-chat` |
| `02-conversations.png` | `chat` |
| `03-translations.png` | `translation-detail` |
| `04-shared-decisions.png` | `goal-active` |
| `05-analytics.png` | `analytics` |

Captures use iOS 26.5, English (U.S.), light appearance, and a 9:41 status bar.
The preview bundle is a local capture/test harness and is never distributed
through the App Store. Toki is the in-app assistant's name; the app and its
Live Activity extension are Glossia and Glossia Activity.

These files are ready for the corresponding screenshot sets in App Store
Connect. Committing them does not upload listing assets or submit an app for
review. See the native README for signing and build-upload automation.
