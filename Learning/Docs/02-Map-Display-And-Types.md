# שלב 2: הצגת מפה, סוגי מפות (`MapType`) ומיקוד אזור (`MapSpan`)

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git (Branch):** `stage/02-map-display-and-types`  
> **קהל יעד:** תלמידים מתחילים בפיתוח אפליקציות מובייל (.NET MAUI)

---

## 1. מה אנחנו בונים בשלב הזה?

לאחר שבשלב 1 הגדרנו את חבילת `Microsoft.Maui.Controls.Maps`, את `.UseMauiMaps()` ואת הרשאות Android, כעת נציג **מפה אינטראקטיבית אמיתית** על המסך!

בשלב זה נלמד:
1. כיצד מוסיפים את פקד ה-`Map` לקובץ XAML בעזרת מרחב השמות `xmlns:maps`.
2. מהם **קואורדינטות (Latitude / Longitude)**, מהו `Location`, ומהו **`MapSpan`** (מיקוד המפה למרכז ולרדיוס).
3. מהם 3 סוגי המפות (`MapType`): **Street**, **Satellite** ו-**Hybrid**.
4. כיצד מעדכנים את המפה מ-`MapDisplayViewModel` בצורה נקייה לפי עקרונות Vanilla C# MVVM.

> **הערת פלטפורמה חשובה:** פקד המפות המובנה של .NET MAUI (`Microsoft.Maui.Controls.Maps`) מציג מפה חיה ב-**Android**, **iOS** ו-**Mac Catalyst** (לא ב-Windows Desktop). כדי לראות את המפה פועלת, מריצים על אימולטור או מכשיר Android. את הלוגיקה בודקים תוך שניות באמצעות בדיקות היחידה!

---

## 2. הוספת פקד `Map` ב-XAML (`Views/MapDisplayPage.xaml`)

כדי להשתמש בפקד `Map` בתוך XAML, מוסיפים קודם הצהרת מרחב שמות (`xmlns:maps`) בראש הדף:

```xml
<ContentPage xmlns="http://schemas.microsoft.com/dotnet/2021/maui"
             xmlns:x="http://schemas.microsoft.com/winfx/2009/xaml"
             xmlns:maps="http://schemas.microsoft.com/dotnet/2021/maui/maps"
             ...>
```

ולאחר מכן מציבים את פקד ה-`<maps:Map>` בתוך ה-`Grid`:

```xml
<maps:Map x:Name="CoffeeMapControl"
          MapType="{Binding SelectedMapType}"
          IsScrollEnabled="True"
          IsZoomEnabled="True" />
```

### תכונות עיקריות של פקד `Map`:
| תכונה | תפקיד |
| :--- | :--- |
| `MapType` | סוג התצוגה: `Street` (מפת רחובות), `Satellite` (תצלום לוויין), או `Hybrid` (לוויין + שמות רחובות). |
| `IsScrollEnabled` | האם המשתמש יכול לגרור את המפה באצבע (`True`/`False`). |
| `IsZoomEnabled` | האם המשתמש יכול לעשות זום (צביטה בשתי אצבעות). |

---

## 3. מושגי יסוד בגיאוגרפיה דיגיטלית: `Location`, `Distance` ו-`MapSpan`

כדי להגיד למפה **איפה להסתכל וכמה קרוב להתמקד**, משתמשים ב-3 אובייקטים מרכזיים:

1. **`Location(latitude, longitude)`** — נקודה מדויקת על פני כדור הארץ:
   * `Latitude` (קו רוחב) — צפון/דרום (בישראל בערך `31.0` עד `33.3`).
   * `Longitude` (קו אורך) — מזרח/מערב (בישראל בערך `34.2` עד `35.8`).
   * לדוגמה, שדרות רוטשילד בתל אביב: `new Location(32.0636, 34.7731)`.
2. **`Distance.FromKilometers(1.2)`** — טווח מרחק (רדיוס) בקילומטרים או במטרים (`Distance.FromMeters(500)`).
3. **`MapSpan.FromCenterAndRadius(center, distance)`** — מגדיר את "חלון הצפייה" של המפה: נקודת מרכז + רדיוס מסביבה.

בקובץ `Services/CoffeeRegionService.cs` בנינו מתודה שמייצרת `MapSpan` בטוח (עם הגבלת רדיוס בין `0.2` ל-`25` ק"מ):

```csharp
var center = new Location(region.Latitude, region.Longitude);
return MapSpan.FromCenterAndRadius(center, Distance.FromKilometers(radiusKm));
```

---

## 4. איך מעבירים פקודת תזוזה למפה בלי לשבור MVVM?

פקד ה-`Map` דורש קריאה למתודה `CoffeeMapControl.MoveToRegion(span)` שנמצאת בצד ה-View (`MapDisplayPage.xaml.cs`).  
כדי שה-`MapDisplayViewModel` לא יהיה תלוי בפקד הגרפי (וכך נוכל לבדוק אותו בקלות ב-Unit Tests!), השתמשנו ב-**Event נקי**:
* ה-ViewModel מחשב את ה-`MapSpan` ומפעיל אירוע: `MoveToRegionRequested?.Invoke(span);`
* דף ה-View (`MapDisplayPage.xaml.cs`) נרשם לאירוע ב-`OnAppearing()`, מבטל רישום ב-`OnDisappearing()` (כדי למנוע דליפות זיכרון), וקורא ל-`CoffeeMapControl.MoveToRegion(span)`.

---

## 5. רישום השכבות ב-`MauiProgram.cs` (Fluent Builder)

שימו לב כמה נקי נראה הרישום של שלב 2 ב-`MauiProgram.cs` בזכות מתודות ה-Extension:
* `RegisterServices()` — מוסיף את `ICoffeeRegionService` -> `CoffeeRegionService`.
* `RegisterViewModels()` — מוסיף את `MapDisplayViewModel`.
* `RegisterViews()` — מוסיף את `MapDisplayPage`.

---

## 6. הרצת הבדיקות
לפני שתעברו למשימה, ודאו שהפתרון מתקמפל ושכל הבדיקות עוברות:
* ב-Visual Studio: `Build -> Build Solution`, ואז `Test -> Test Explorer -> Run All Tests`.
* או בטרמינל: `dotnet build` ולאחריו `dotnet test`.

למשימת התרגול שלכם, פתחו את [`Docs/Assignments/02-Map-Display-Assignment.pdf`](Assignments/02-Map-Display-Assignment.pdf).
