# תיעוד בדיקות יחידה — CoffeeMap (`MauiGoogleMapSample.Tests`)

כל הבדיקות נכתבו באמצעות **`xunit.v3`** בתבנית **Arrange – Act – Assert (AAA)**.

## שלב 1 (`stage/01-setup-and-permissions`)

### 1. `MapConfigurationValidatorTests` (בדיקת שירות `MapConfigurationValidator`)
| שם הבדיקה | תרחיש נבדק | תוצאה צפויה |
| :--- | :--- | :--- |
| `ValidateApiKey_WhenNullOrEmpty_ReturnsInvalid` | מפתח ריק או רווחים בלבד | `IsValid == false`, כותרת מכילה `"חסר"` |
| `ValidateApiKey_WhenPlaceholder_ReturnsInvalidWithPlaceholderMessage` | מפתח זהה ל-`YOUR_GOOGLE_MAPS_API_KEY_HERE` | `IsValid == false`, כותרת מכילה `"Placeholder"` |
| `ValidateApiKey_WhenTooShort_ReturnsInvalid` | מפתח קצר מ-20 תווים | `IsValid == false`, כותרת מכילה `"קצר"` |
| `ValidateApiKey_WhenValidLength_ReturnsValid` | מפתח בפורמט תקין | `IsValid == true`, כותרת מכילה `"תקין"` |

### 2. `SetupStatusViewModelTests` (בדיקת `SetupStatusViewModel`)
| שם הבדיקה | תרחיש נבדק | תוצאה צפויה |
| :--- | :--- | :--- |
| `Constructor_InitializesWithPlaceholderAndInvalidStatus` | אתחול ראשוני של ה-ViewModel | נטען עם Placeholder ו-`IsConfigured == false` |
| `ValidateKeyCommand_WhenApiKeyEmpty_CannotExecute` | ניקוי שדה המפתח | `ValidateKeyCommand.CanExecute(null) == false` |
| `ValidateKeyCommand_WhenValidKeyEntered_UpdatesIsConfiguredToTrue` | הזנת מפתח תקין והפעלת הפקודה | `CanExecute == true`, `IsConfigured == true` |
| `ResetToPlaceholderCommand_RestoresPlaceholderAndInvalidState` | הפעלת כפתור האיפוס | מחזיר את `ApiKeyInput` ל-Placeholder ו-`IsConfigured == false` |
