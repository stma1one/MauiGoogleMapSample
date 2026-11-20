# שלב 4: מיקום המשתמש (GPS), הרשאות בזמן ריצה וחישוב מרחקים

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git (Branch):** `stage/04-gps-and-user-location`  
> **קהל יעד:** תלמידים מתחילים בפיתוח אפליקציות מובייל (.NET MAUI)

---

## 1. הרשאות התקנה לעומת הרשאות בזמן ריצה (Runtime Permissions)

בשלב 1 הצהרנו ב-`AndroidManifest.xml` על `ACCESS_FINE_LOCATION` ו-`ACCESS_COARSE_LOCATION`.  
אך באנדרואיד המודרני זה **אינו מספיק**! כדי להגן על המשתמש, האפליקציה חייבת לבקש אישור מפורש **בזמן ריצה** לפני שהיא ניגשת ל-GPS או מפעילה `IsShowingUser="True"` על המפה:

```csharp
PermissionStatus status = await Permissions.CheckStatusAsync<Permissions.LocationWhenInUse>();
if (status != PermissionStatus.Granted)
{
    status = await Permissions.RequestAsync<Permissions.LocationWhenInUse>();
}
```

רק לאחר שקיבלנו `PermissionStatus.Granted`, מותר לקרוא למיקום ה-GPS ולהציג את הנקודה הכחולה של המשתמש (`IsShowingUser = true`).

---

## 2. קריאת מיקום ה-GPS (`Geolocation`) וחישוב מרחק לתחנת קפה קרובה

לאחר שיש הרשאה, מבקשים את מיקום המכשיר באופן אסינכרוני (`async`/`await` כדי לא לתקוע את ממשק המשתמש):

```csharp
var request = new GeolocationRequest(GeolocationAccuracy.Medium, TimeSpan.FromSeconds(10));
Location? location = await Geolocation.Default.GetLocationAsync(request);
```

כדי למצוא איזו תחנת קפה היא הקרובה ביותר למשתמש, משתמשים בפונקציה המובנית של .NET MAUI לחישוב מרחק אווירי בין שתי נקודות:

```csharp
double distanceKm = Location.CalculateDistance(userLocation, station.Location, DistanceUnits.Kilometers);
```

---

## 3. עבודה אסינכרונית בטוחה ב-ViewModel (`IsLoading` + `try/catch/finally`)

ב-`ViewModels/UserLocationViewModel.cs` אנו מדגימים 3 כללי זהב של תכנות אסינכרוני ב-MAUI:
1. משתמשים ב-`IsLoading` המחובר ל-`<ActivityIndicator>` (ולא ב-`Page.IsBusy` המיושן).
2. משביתים את הכפתור בזמן טעינה באמצעות `CanExecute => !IsLoading` + `ChangeCanExecute()`.
3. עוטפים את העבודה ב-`try / catch / finally` כדי שתמיד נכבה את `IsLoading = false` גם אם אירעה שגיאה.

---

## 4. איך בודקים GPS ב-Unit Tests בלי מכשיר אמיתי? (תבנית Fake Service)

במחשב הפיתוח אין מקלט GPS אמיתי. לכן הפרדנו את הגישה לחיישן מאחורי ממשק **`ILocationService`**!  
בפרויקט הבדיקות (`UserLocationViewModelTests.cs`), יצרנו מחלקת דמה קטנה (`FakeLocationService`) שמחזירה מיקום קבוע ליד רחוב שנקין — וכך בדקנו תוך שנייה אחת ש-`UserLocationViewModel` מוצא את `"קליית שנקין"` כתחנה הקרובה ביותר, וגם יודע להתמודד עם דחיית הרשאה או שגיאת חיישן!

* להרצת הבדיקות: ב-Visual Studio לחצו `Test -> Test Explorer -> Run All Tests`, או בטרמינל הריצו `dotnet build` ו-`dotnet test`.

למשימת התרגול שלכם, פתחו את [`Docs/Assignments/04-GPS-And-User-Location-Assignment.pdf`](Assignments/04-GPS-And-User-Location-Assignment.pdf).
