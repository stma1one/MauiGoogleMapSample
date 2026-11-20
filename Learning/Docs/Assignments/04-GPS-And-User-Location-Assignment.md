# משימה 4: איתור כל תחנות הקפה בטווח הליכה (רדיוס 1 ק"מ)

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git בסיס:** `stage/04-gps-and-user-location`  
> **זמן משוער:** 40–50 דקות

---

## מטרת המשימה
לתרגל חישובי מרחקים גיאוגרפיים עם `Location.CalculateDistance`, הרחבת ממשק שירות (`ILocationService`), וכתיבת בדיקת יחידה אסינכרונית עם `FakeLocationService`.

---

## חלק א': הוספת מתודת סינון לפי רדיוס ב-`ILocationService`

1. פתחו את `MauiGoogleMapSample/Services/ILocationService.cs` והוסיפו את החתימה:
   ```csharp
   IReadOnlyList<CoffeeStation> GetStationsWithinRadius(
       Location userLocation,
       IEnumerable<CoffeeStation> stations,
       double maxDistanceKm);
   ```
2. פתחו את `MauiGoogleMapSample/Services/LocationService.cs` וממשו את המתודה כך שתחזיר את כל התחנות שהמרחק שלהן מ-`userLocation` קטן או שווה ל-`maxDistanceKm`, **ממוינות מהקרובה לרחוקה**.

---

## חלק ב': הצגת כמות התחנות בטווח הליכה (1 ק"מ) במסך

1. פתחו את `MauiGoogleMapSample/ViewModels/UserLocationViewModel.cs`.
2. הוסיפו מאפיין חדש `NearbyCountSummary` (`string`) עם `OnPropertyChanged()`.
3. בתוך `ExecuteLocateMeAsync()`, לאחר מציאת מיקום המשתמש, קראו ל-`_locationService.GetStationsWithinRadius(result.Location, Stations, 1.0)` ועדכנו את `NearbyCountSummary` בטקסט: `"נמצאו X תחנות קפה בטווח של 1 ק\"מ ממך"`.
4. הציגו את `NearbyCountSummary` באמצעות `<Label Text="{Binding NearbyCountSummary}" />` בתחתית `Views/UserLocationPage.xaml`.

---

## חלק ג': בדיקת יחידה ואימות

1. פתחו את `MauiGoogleMapSample.Tests/UserLocationViewModelTests.cs`.
2. הוסיפו את מימוש `GetStationsWithinRadius` ל-`FakeLocationService` (העבירו ל-`_realCalculator`).
3. הוסיפו בדיקה `ExecuteLocateMeAsync_UpdatesNearbyCountSummaryWithinOneKilometer` שמוודאת שכשמשתמש נמצא ברחוב רוטשילד (`32.0636, 34.7731`), `NearbyCountSummary` מציג לפחות 2 תחנות קפה קרובות (ולא כולל את נמל תל אביב המרוחק).
4. בצעו **Build** והריצו את כל הבדיקות ב-Visual Studio (`Test -> Test Explorer -> Run All Tests`) או בטרמינל (`dotnet build` ו-`dotnet test`). ודאו ש-`Failed: 0`!
