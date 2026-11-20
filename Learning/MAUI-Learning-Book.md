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
