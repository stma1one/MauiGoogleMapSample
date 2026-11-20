# תרשימי ארכיטקטורה ופרומפטים לתיק הפרויקט (883589)

קובץ זה נוצר אוטומטית מתוך קוד הפרויקט על ידי `Generate-Architecture-Diagrams.py`.
הוא מכיל את **תרשים זרימת המסכים (Screen Flow Diagram)** ואת **תרשים המחלקות (UML Class Diagram)** — כולל **תמונות PNG ויזואליות מוכנות** (`Learning/Images/Screen-Flow.png` ו-`Learning/Images/Architecture-UML.png`) — לשילוב בפרק **"מבנה / ארכיטקטורה של הפרויקט"** בתיק הפרויקט ובספר הלמידה (`MAUI-Learning-Book.pdf`).

---

## 1. תרשים זרימת מסכים (Screen Flow Diagram)

![תרשים זרימת מסכים (Screen Flow)](../Images/Screen-Flow.png)

```mermaid
flowchart TD
  AppShell(["AppShell (נקודת פתיחה וניווט)"])
  AppShell -->|"Shell Tab / Flyout"| MapDisplayPage
  AppShell -->|"Shell Tab / Flyout"| MainPage
```

### פרומפט שמור ליצירת תרשים זרימת המסכים בעיצוב גרפי:
> צור תרשים זרימת מסכים (Screen Flow Diagram) נקי וברור עבור אפליקציית .NET MAUI. מסך הפתיחה וההיררכיה הראשיים מנוהלים ב-`AppShell`, והמסכים בפרויקט הם: `MainPage, MapDisplayPage`. הצג חיצים ברורים למעברי הניווט (`Shell.Current.GoToAsync`) בין המסכים לפי מבנה ה-Mermaid שלעיל.

---

## 2. תרשים מחלקות (UML Class Diagram)

![תרשים מחלקות (UML Class Diagram)](../Images/Architecture-UML.png)

```mermaid
classDiagram
  direction TB
  class AppShell {
  }
  class MainPage {
  }
  class CoffeeRegion {
    +string Name
    +string Description
    +double Latitude
    +double Longitude
    +double DefaultRadiusKm
  }
  class CoffeeRegionService {
    +GetDefaultRegions() IReadOnlyList~CoffeeRegion~
    +BuildMapSpan() MapSpan
  }
  class ICoffeeRegionService {
    <<interface>>
  }
  class IMapConfigurationValidator {
    <<interface>>
    +MapConfigCheckResult() record
  }
  class MapConfigurationValidator {
    +ValidateApiKey() MapConfigCheckResult
  }
  class BaseViewModel {
  }
  class MapDisplayViewModel {
    +ObservableCollection~CoffeeRegion~ Regions
    +GetCurrentMapSpan() MapSpan
  }
  class SetupStatusViewModel {
  }
  class MapDisplayPage {
  }
  class ArchitectureSmokeTests {
    +TestHarness_WhenInitialized_PassesSanityCheck() void
  }
  class CoffeeRegionServiceTests {
    +GetDefaultRegions_ReturnsThreeIsraeliCoffeeHubs() void
    +BuildMapSpan_ReturnsSpanCenteredOnRegionCoordinates() void
    +BuildMapSpan_WhenRadiusTooSmall_ClampsToMinimum() void
  }
  class MapConfigurationValidatorTests {
    +ValidateApiKey_WhenNullOrEmpty_ReturnsInvalid() void
    +ValidateApiKey_WhenPlaceholder_ReturnsInvalidWithPlaceholderMessage() void
    +ValidateApiKey_WhenTooShort_ReturnsInvalid() void
    +ValidateApiKey_WhenValidLength_ReturnsValid() void
  }
  class MapDisplayViewModelTests {
    +Constructor_InitializesWithStreetMapAndFirstRegion() void
    +SetMapTypeCommand_SwitchesToSatelliteAndHybrid() void
    +SelectRegionCommand_UpdatesRegionAndRaisesMoveToRegionEvent() void
    +ZoomInAndOutCommands_UpdateRadiusAndRespectCanExecuteBounds() void
  }
  class SetupStatusViewModelTests {
    +Constructor_InitializesWithPlaceholderAndInvalidStatus() void
    +ValidateKeyCommand_WhenApiKeyEmpty_CannotExecute() void
    +ValidateKeyCommand_WhenValidKeyEntered_UpdatesIsConfiguredToTrue() void
    +ResetToPlaceholderCommand_RestoresPlaceholderAndInvalidState() void
  }
  ContentPage <|-- MainPage
  MainPage ..> SetupStatusViewModel : DI
  ICoffeeRegionService <|-- CoffeeRegionService
  IMapConfigurationValidator <|-- MapConfigurationValidator
  INotifyPropertyChanged <|-- BaseViewModel
  BaseViewModel <|-- MapDisplayViewModel
  MapDisplayViewModel ..> ICoffeeRegionService : DI
  BaseViewModel <|-- SetupStatusViewModel
  SetupStatusViewModel ..> IMapConfigurationValidator : DI
  ContentPage <|-- MapDisplayPage
  MapDisplayPage ..> MapDisplayViewModel : DI
```

### פרומפט שמור ליצירת תרשים ה-UML בעיצוב גרפי:
> צור תרשים מחלקות UML תקני (UML Class Diagram) המחולק לשכבות MVVM (`Models`, `Services`, `ViewModels`, `Views`) עבור פרויקט ה-.NET MAUI, כולל קשרי ירושה (`<|--`), הכלה, והזרקת תלויות בבנאי (`..> DI`), בהתבסס על הגדרת ה-Mermaid שלעיל.
