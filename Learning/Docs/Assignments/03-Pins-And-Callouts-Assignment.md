# משימה 3: סינון תחנות קפה מומלצות (`Top Rated`) על המפה

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git בסיס:** `stage/03-pins-and-callouts`  
> **זמן משוער:** 35–45 דקות

---

## מטרת המשימה
לתרגל עבודה עם `ObservableCollection<CoffeeStation>`, סינון סיכות (`Pins`) על המפה בזמן אמת דרך MVVM, וכתיבת בדיקות יחידה ב-`xunit.v3`.

---

## חלק א': הוספת מתודת סינון לפי דירוג ב-`CoffeeStationService`

1. פתחו את `MauiGoogleMapSample/Services/ICoffeeStationService.cs` והוסיפו חתימה למתודה חדשה:
   ```csharp
   IReadOnlyList<CoffeeStation> GetTopRatedStations(double minRating);
   ```
2. פתחו את `MauiGoogleMapSample/Services/CoffeeStationService.cs` וממשו את המתודה כך שתחזיר רק את תחנות הקפה שהדירוג שלהן (`Rating`) גדול או שווה ל-`minRating`.

---

## חלק ב': הוספת פקודה וכפתור "מומלצות (4.5★+)"

1. פתחו את `MauiGoogleMapSample/ViewModels/CoffeePinsViewModel.cs`.
2. הוסיפו פקודה חדשה `FilterTopRatedCommand` (`ICommand`) שקוראת ל-`_stationService.GetTopRatedStations(4.5)`, מנקה את `Stations`, מוסיפה את התחנות שנמצאו ומעדכנת את `SelectedStationBanner` בהודעה: `"מוצגות X תחנות קפה מומלצות (4.5★ ומעלה)"`.
3. פתחו את `MauiGoogleMapSample/Views/CoffeePinsPage.xaml` והוסיפו כפתור `"מומלצות ★"` שמחובר ל-`FilterTopRatedCommand`.

---

## חלק ג': הוספת בדיקות יחידה ואימות

1. ב-`MauiGoogleMapSample.Tests/CoffeeStationServiceTests.cs` הוסיפו בדיקה `GetTopRatedStations_WithMinRating4Point5_ReturnsOnlyHighRatedStations` (בדקו שמוחזרות בדיוק 2 תחנות ושלכולן `Rating >= 4.5`).
2. ב-`MauiGoogleMapSample.Tests/CoffeePinsViewModelTests.cs` הוסיפו בדיקה `FilterTopRatedCommand_UpdatesStationsAndBanner`.
3. בצעו **Build** והריצו את כל הבדיקות ב-Visual Studio (`Test -> Test Explorer -> Run All Tests`) או בטרמינל (`dotnet build` ו-`dotnet test`). ודאו ש-`Failed: 0`!
