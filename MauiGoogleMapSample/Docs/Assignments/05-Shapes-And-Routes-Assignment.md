# משימה 5: ציור מתחם קפה באמצעות מצולע (`Polygon`)

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git בסיס:** `stage/05-shapes-and-routes`  
> **זמן משוער:** 40–50 דקות

---

## מטרת המשימה
לתרגל ציור צורת `Polygon` על `Map.MapElements`, ניהול מצב שכבות ב-ViewModel, וכתיבת בדיקות יחידה ב-`xunit.v3`.

---

## חלק א': הוספת מתודת בניית `Polygon` ב-`ICoffeeRouteService`

1. פתחו את `MauiGoogleMapSample/Services/ICoffeeRouteService.cs` והוסיפו:
   ```csharp
   Polygon BuildCoffeeZonePolygon(IEnumerable<CoffeeStation> stations);
   ```
2. פתחו את `MauiGoogleMapSample/Services/CoffeeRouteService.cs` וממשו את המתודה כך שתיצור `Polygon` עם:
   * `StrokeColor = Color.FromArgb("#15803D")` (ירוק)
   * `StrokeWidth = 4`
   * `FillColor = Color.FromArgb("#3315803D")` (ירוק שקוף למחצה)
   * כל מיקומי התחנות מתווספים ל-`polygon.Geopath`.

---

## חלק ב': כפתור "מתחם קפה (Polygon)" ב-ViewModel ובמסך

1. פתחו את `MauiGoogleMapSample/ViewModels/CoffeeRoutesViewModel.cs`:
   * הוסיפו מאפיין `ShowPolygon` (`bool`, ברירת מחדל `false`) עם `OnPropertyChanged()`, עדכון `ClearOverlaysCommand.ChangeCanExecute()`, והפעלת `MapElementsChanged?.Invoke()`.
   * הוסיפו פקודה `TogglePolygonCommand` (`ICommand`).
   * ב-`BuildActiveMapElements()`: אם `ShowPolygon && Stations.Count >= 3`, הוסיפו את `_routeService.BuildCoffeeZonePolygon(Stations)` לרשימת האלמנטים.
   * עדכנו את `CanExecuteClearOverlays()` כך שיתחשב גם ב-`ShowPolygon`, ואת `ExecuteClearOverlays()` שיאפס גם אותו ל-`false`.
2. פתחו את `MauiGoogleMapSample/Views/CoffeeRoutesPage.xaml` והוסיפו כפתור `"מתחם קפה"` המחובר ל-`TogglePolygonCommand`.

---

## חלק ג': בדיקות יחידה ואימות סופי

1. ב-`MauiGoogleMapSample.Tests/CoffeeRouteServiceTests.cs` הוסיפו בדיקה `BuildCoffeeZonePolygon_ContainsAllStationLocations`.
2. ב-`MauiGoogleMapSample.Tests/CoffeeRoutesViewModelTests.cs` הוסיפו בדיקה `TogglePolygonCommand_AddsPolygonToActiveMapElements`.
3. בצעו **Build** והריצו את כל הבדיקות ב-Visual Studio (`Test -> Test Explorer -> Run All Tests`) או בטרמינל (`dotnet build` ו-`dotnet test`). ודאו שכל הבדיקות עוברות (`Failed: 0`)!
