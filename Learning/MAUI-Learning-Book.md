# ספר למידה — CoffeeMap (.NET MAUI Google Maps)

ספר למידה זה מתעד את בניית אפליקציית **CoffeeMap** (איתור תחנות קפה ב-.NET MAUI) שלב אחר שלב, בענפי Git נפרדים, תוך שמירה על ארכיטקטורת Vanilla C# MVVM, הרשאות Android, ובדיקות יחידה ב-`xunit.v3`.

---

## שלב 1: תשתית, חבילות NuGet והרשאות Android (`stage/01-setup-and-permissions`)

* **מצב עבודה:** `MAXIMIZE CODE GENERATED`
* **מטרת השלב:** הכנת תשתית המפות של .NET MAUI, התקנת `Microsoft.Maui.Controls.Maps`, הגדרת הרשאות מיקום ו-API Key Placeholder ב-`AndroidManifest.xml`, והדגמת הפרדת שכבות (Service + ViewModel + View + Tests).
* **קבצים שנוצרו/עודכנו:**
  * `MauiGoogleMapSample/MauiGoogleMapSample.csproj` — הוספת `Microsoft.Maui.Controls.Maps` (`Version="$(MauiVersion)"`).
  * `MauiGoogleMapSample/MauiProgram.cs` — הפעלת `.UseMauiMaps()` ורישום DI.
  * `MauiGoogleMapSample/Platforms/Android/AndroidManifest.xml` — הרשאות `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` ו-`<meta-data>` עבור `com.google.android.geo.API_KEY`.
  * `MauiGoogleMapSample/Services/IMapConfigurationValidator.cs` ו-`MapConfigurationValidator.cs`.
  * `MauiGoogleMapSample/ViewModels/BaseViewModel.cs` ו-`SetupStatusViewModel.cs`.
  * `MauiGoogleMapSample/MainPage.xaml` ו-`MainPage.xaml.cs`.
  * `MauiGoogleMapSample.Tests/MapConfigurationValidatorTests.cs` ו-`SetupStatusViewModelTests.cs`.
  * מדריך ומשימה לתלמיד ב-PDF: `MauiGoogleMapSample/Docs/01-Setup-And-Permissions.pdf` ו-`MauiGoogleMapSample/Docs/Assignments/01-Setup-And-Permissions-Assignment.pdf`.
* **ראו פירוט מלא ותצוגת מסך בפרק:** [שלב 1 — הגדרות והרשאות (`MainPage`)](Guides/MainPage-Guide.md)

---

## שלב 2: הצגת מפה, סוגי מפות (`MapType`) ומיקוד אזור (`stage/02-map-display-and-types`)

* **מצב עבודה:** `MAXIMIZE CODE GENERATED`
* **מטרת השלב:** הוספת פקד `<maps:Map>` ב-XAML, מעבר בין סוגי מפות (`Street`, `Satellite`, `Hybrid`), שליטה בזום (`ZoomInCommand`, `ZoomOutCommand` עם `CanExecute`), ומעבר בין אזורי קפה מרכזיים באמצעות `MapSpan.FromCenterAndRadius`.
* **קבצים שנוצרו/עודכנו:**
  * `MauiGoogleMapSample/Models/CoffeeRegion.cs`
  * `MauiGoogleMapSample/Services/ICoffeeRegionService.cs` ו-`CoffeeRegionService.cs`
  * `MauiGoogleMapSample/ViewModels/MapDisplayViewModel.cs`
  * `MauiGoogleMapSample/Views/MapDisplayPage.xaml` ו-`MapDisplayPage.xaml.cs`
  * `MauiGoogleMapSample/AppShell.xaml` ו-`MauiProgram.cs` (רישום Fluent Builder)
  * `MauiGoogleMapSample.Tests/CoffeeRegionServiceTests.cs` ו-`MapDisplayViewModelTests.cs`
  * מסמכי PDF לתלמיד: `MauiGoogleMapSample/Docs/02-Map-Display-And-Types.pdf` ו-`MauiGoogleMapSample/Docs/Assignments/02-Map-Display-Assignment.pdf`.
* **ראו פירוט מלא ותצוגת מסך בפרק:** [שלב 2 — תצוגת מפה (`MapDisplayPage`)](Guides/MapDisplayPage-Guide.md)

---

## שלב 3: סיכות (`Pins`), קישור נתונים ואירועי לחיצה (`stage/03-pins-and-callouts`)

* **מטרת השלב:** הצגת תחנות קפה כסיכות `<maps:Pin>` באמצעות `ItemsSource` ו-`ItemTemplate`, סינון חי, וטיפול ב-`MarkerClicked` ו-`InfoWindowClicked` (עם `DisplayAlertAsync`).
* **מסמכי PDF לתלמיד:** `MauiGoogleMapSample/Docs/03-Pins-And-Callouts.pdf` ו-`MauiGoogleMapSample/Docs/Assignments/03-Pins-And-Callouts-Assignment.pdf`.
* **ראו פירוט ותצוגת מסך בפרק:** [שלב 3 — סיכות (`CoffeePinsPage`)](Guides/CoffeePinsPage-Guide.md)

---

## שלב 4: מיקום המשתמש (GPS), הרשאות בזמן ריצה וחישוב מרחקים (`stage/04-gps-and-user-location`)

* **מטרת השלב:** בקשת `Permissions.LocationWhenInUse`, קריאת `Geolocation`, הצגת `IsShowingUser`, חישוב תחנת הקפה הקרובה ביותר, ובדיקות יחידה עם `FakeLocationService`.
* **מסמכי PDF לתלמיד:** `MauiGoogleMapSample/Docs/04-GPS-And-User-Location.pdf` ו-`MauiGoogleMapSample/Docs/Assignments/04-GPS-And-User-Location-Assignment.pdf`.
* **ראו פירוט ותצוגת מסך בפרק:** [שלב 4 — מיקום GPS (`UserLocationPage`)](Guides/UserLocationPage-Guide.md)

---

## שלב 5: ציור מסלולים (`Polyline`) וצורות גיאוגרפיות (`Circle` / `Polygon`) (`stage/05-shapes-and-routes`)

* **מטרת השלב:** ציור `Polyline` (מסלול סיור קפה) ו-`Circle` (אזור משלוח) מעל `Map.MapElements`, חישוב מרחק מסלול כולל, ושליטה בשכבות דרך MVVM ו-`ICommand.CanExecute`.
* **מסמכי PDF לתלמיד:** `MauiGoogleMapSample/Docs/05-Shapes-And-Routes.pdf` ו-`MauiGoogleMapSample/Docs/Assignments/05-Shapes-And-Routes-Assignment.pdf`.
* **ראו פירוט ותצוגת מסך בפרק:** [שלב 5 — מסלולים וצורות (`CoffeeRoutesPage`)](Guides/CoffeeRoutesPage-Guide.md)
