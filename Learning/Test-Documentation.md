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

## שלב 2 (`stage/02-map-display-and-types`)

### 3. `CoffeeRegionServiceTests` (בדיקת שירות `CoffeeRegionService`)
| שם הבדיקה | תרחיש נבדק | תוצאה צפויה |
| :--- | :--- | :--- |
| `GetDefaultRegions_ReturnsThreeIsraeliCoffeeHubs` | שליפת אזורי ברירת מחדל | מחזיר 3 אזורים (תל אביב, ירושלים, חיפה) |
| `BuildMapSpan_ReturnsSpanCenteredOnRegionCoordinates` | בניית `MapSpan` לאזור תל אביב ברדיוס 2 ק"מ | מרכז ורדיוס תואמים לקואורדינטות תל אביב |
| `BuildMapSpan_WhenRadiusTooSmall_ClampsToMinimum` | רדיוס קטן מדי (`0.01`) | מוגבל למינימום בטוח (`0.2` ק"מ) |

### 4. `MapDisplayViewModelTests` (בדיקת `MapDisplayViewModel`)
| שם הבדיקה | תרחיש נבדק | תוצאה צפויה |
| :--- | :--- | :--- |
| `Constructor_InitializesWithStreetMapAndFirstRegion` | אתחול ברירת מחדל | `MapType.Street`, 3 אזורים, האזור הראשון נבחר |
| `SetMapTypeCommand_SwitchesToSatelliteAndHybrid` | החלפת סוג מפה | עובר ל-`Satellite` ול-`Hybrid` ומעדכן `RegionSummary` |
| `SelectRegionCommand_UpdatesRegionAndRaisesMoveToRegionEvent` | בחירת אזור ירושלים | מעדכן `SelectedRegion` ומפעיל `MoveToRegionRequested` |
| `ZoomInAndOutCommands_UpdateRadiusAndRespectCanExecuteBounds` | זום פנימה והחוצה בגבולות | מקטין רדיוס ומשבית `ZoomInCommand` בגבול המינימלי |

## שלב 3 (`stage/03-pins-and-callouts`)

### 5. `CoffeeStationServiceTests` & `CoffeePinsViewModelTests`
| שם הבדיקה | תרחיש נבדק | תוצאה צפויה |
| :--- | :--- | :--- |
| `GetStations_ReturnsFourStationsWithValidLocations` | שליפת תחנות קפה | 4 תחנות עם קואורדינטות תקינות |
| `FilterStations_BySpecialty_ReturnsMatchingStationsOnly` | סינון לפי `"אספרסו"` | מחזיר בדיוק 2 תחנות תואמות |
| `FilterStations_WhenQueryEmpty_ReturnsAllStations` | שאילתה ריקה | מחזיר את כל 4 התחנות |
| `Constructor_LoadsAllStationsAndDisablesClearFilter` | אתחול `CoffeePinsViewModel` | 4 תחנות נטענות ו-`ClearFilterCommand` מושבת |
| `FilterCommand_FiltersStationsAndClearFilterRestoresAll` | סינון וניקוי סינון | מסנן ל-1 ומנקה חזרה ל-4 |
| `SelectStationByNameCommand_UpdatesSelectedStationAndBanner` | בחירת סיכה לפי שם | מעדכן `SelectedStation` ופס מידע |

## שלב 4 (`stage/04-gps-and-user-location`)

### 6. `UserLocationViewModelTests` (עם `FakeLocationService`)
| שם הבדיקה | תרחיש נבדק | תוצאה צפויה |
| :--- | :--- | :--- |
| `ExecuteLocateMeAsync_WhenPermissionGranted_SetsShowingUserAndFindsNearestStation` | הרשאה אושרה ומיקום ליד שנקין | `IsShowingUser == true`, מוצא `"קליית שנקין"` ומפעיל `MoveToRegionRequested` |
| `ExecuteLocateMeAsync_WhenPermissionDenied_DisablesShowingUserAndReportsError` | הרשאת מיקום נדחתה | `IsShowingUser == false`, הודעת שגיאה ידידותית |
| `ExecuteLocateMeAsync_WhenServiceThrows_RecoversGracefullyAndResetsIsLoading` | חריגה מחיישן GPS | התאוששות מסודרת ו-`IsLoading == false` |

## שלב 5 (`stage/05-shapes-and-routes`)

### 7. `CoffeeRouteServiceTests` & `CoffeeRoutesViewModelTests`
| שם הבדיקה | תרחיש נבדק | תוצאה צפויה |
| :--- | :--- | :--- |
| `BuildCoffeeTourPolyline_ContainsOneGeopathPointPerStation` | בניית `Polyline` | כמות נקודות ב-`Geopath` זהה למספר התחנות |
| `BuildDeliveryZoneCircle_ClampsSmallRadiusToMinimum50Meters` | רדיוס קטן מ-50 מ' | מוגבל למינימום 50 מ' |
| `CalculateTotalTourDistanceKm_ReturnsPositiveDistanceForMultipleStations` | חישוב אורך סיור הקפה | מחזיר מרחק כולל תקין בק"מ |
| `Constructor_StartsWithBothOverlaysActiveAndTwoMapElements` | אתחול `CoffeeRoutesViewModel` | 2 אלמנטים (`Polyline` + `Circle`) פעילים |
| `ClearOverlaysCommand_RemovesAllElementsAndDisablesCommand` | ניקוי שכבות | מרוקן את האלמנטים ומשבית `ClearOverlaysCommand` |
| `ToggleRouteCommand_TogglesPolylineAndRaisesMapElementsChanged` | הסתרת מסלול | מסיר `Polyline`, משאיר `Circle`, ומפעיל אירוע |

## עדכון: `SecureStorage` וניווט `Flyout`
| שם הבדיקה | תרחיש נבדק | תוצאה צפויה |
| :--- | :--- | :--- |
| `ExecuteSaveKeyAsync_WhenValidKey_SavesToSecureStorageAndCanBeLoadedBack` | שמירת מפתח ב-`FakeSecureKeyStorageService` וטעינה מחדש | המפתח נשמר ונטען מחדש ללא שמירה בקוד המקור |
| `ClearSavedKeyCommand_ClearsSecureStorageAndRestoresPlaceholder` | מחיקת מפתח מוצפן | האחסון מתרוקן והשדה חוזר ל-Placeholder |
| `LoadStoredKeyStatusAsync_WhenKeyStored_DisplaysMaskedKeyFromSecureStorage` | שליפת מפתח ב-`MapDisplayViewModel` | מציג סטטוס מוסתר (`AIza••••9999`) ללא חשיפת המפתח המלא |
