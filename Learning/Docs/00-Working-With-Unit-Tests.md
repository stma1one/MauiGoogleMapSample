# מדריך למתחילים: עבודה עם בדיקות יחידה (Unit Tests) ב-.NET MAUI

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ספריית בדיקות:** `xunit.v3`  
> **פרויקט הבדיקות:** `MauiGoogleMapSample.Tests`

---

## 1. מהן בדיקות יחידה (Unit Tests) ולמה אנחנו משתמשים בהן?

כשאנחנו בונים אפליקציית מובייל ב-.NET MAUI, להריץ בכל פעם את האימולטור של Android רק כדי לבדוק אם פונקציה קטנה עובדת (למשל: בדיקת תקינות של מפתח API או חישוב מרחק לתחנת קפה) לוקח הרבה זמן.

**בדיקת יחידה (Unit Test)** היא פונקציית C# קטנה ומהירה שבודקת **יחידת קוד אחת** (למשל מחלקת `Service` או `ViewModel`) באופן אוטומטי, תוך שניות בודדות, ובלי להפעיל את המסך או את האימולטור.

### מה מרוויחים מזה?
* **בדיקה מהירה:** בודקים לוגיקה תוך 2–3 שניות.
* **ביטחון בשינויים:** אם שיניתם קוד ושברתם משהו שעבד קודם — הבדיקות יתריעו מיד.
* **סדר בקוד:** בדיקות מעודדות אותנו לכתוב קוד נקי ומופרד (MVVM — לוגיקה ב-`Services` וב-`ViewModels`, ולא תקועה בתוך ה-XAML).

---

## 2. איך בנוי פרויקט הבדיקות בפתרון (Solution)?

כשפותחים את ה-Solution Explorer ב-Visual Studio רואים **שני פרויקטים**:
1. **`MauiGoogleMapSample`** — אפליקציית ה-.NET MAUI עצמה (מסכי XAML, `ViewModels`, `Services`, `Models`, והגדרות Android).
2. **`MauiGoogleMapSample.Tests`** — פרויקט בדיקות נפרד שמכיל רק קבצי בדיקה (כמו `MapConfigurationValidatorTests.cs` ו-`SetupStatusViewModelTests.cs`).

פרויקט הבדיקות מקושר לפרויקט הראשי באמצעות **Project Reference**, כך שהוא יכול ליצור אובייקטים מהאפליקציה (למשל `new MapConfigurationValidator()`) ולקרוא למתודות שלהם כדי לבדוק אותן.

---

## 3. מבנה של בדיקה אחת — תבנית AAA

כל בדיקת יחידה מסומנת בתכונה **`[Fact]`** מעל המתודה, ומחולקת ל-3 חלקים קבועים שנקראים **AAA (Arrange – Act – Assert)**:

```csharp
using MauiGoogleMapSample.Services;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class MapConfigurationValidatorTests
{
    [Fact]
    public void ValidateApiKey_WhenPlaceholder_ReturnsInvalidWithPlaceholderMessage()
    {
        // 1. Arrange (הכנה) — יוצרים את האובייקטים והנתונים שנדרשים לבדיקה
        var validator = new MapConfigurationValidator();

        // 2. Act (הפעלה) — מפעילים בדיוק את המתודה שאנחנו רוצים לבדוק
        MapConfigCheckResult result = validator.ValidateApiKey(validator.PlaceholderKey);

        // 3. Assert (אימות) — בודקים שהתוצאה שהתקבלה תואמת למה שציפינו
        Assert.False(result.IsValid);
        Assert.Contains("Placeholder", result.StatusTitle);
    }
}
```

### משמעות כל חלק:
* **`[Fact]`** — אומר ל-Visual Studio ול-`xUnit`: "המתודה הזו היא בדיקה שיש להריץ".
* **שם הבדיקה** — מומלץ לקרוא לבדיקה בתבנית ברורה: `שםהמתודה_המצבהנבדק_התוצאההצפויה`.
* **Arrange (הכנה)** — יוצרים מופע של המחלקה הנבדקת ומכינים קלט לדוגמה.
* **Act (הפעלה)** — שורה אחת (או שתיים) שמריצה את הפעולה הנבדקת ושומרת את התוצאה במשתנה.
* **Assert (אימות)** — פקודות בדיקה שמוודאות שהתוצאה נכונה:
  * `Assert.True(condition)` — בודק שהתנאי אמת.
  * `Assert.False(condition)` — בודק שהתנאי שקר.
  * `Assert.Equal(expected, actual)` — בודק ששני ערכים שווים בדיוק.
  * `Assert.Contains("טקסט", actualString)` — בודק שמחרוזת מכילה תת-מחרוזת מסוימת.

---

## 4. איך מריצים את הבדיקות?

יש **שתי דרכים פשוטות** להריץ את הבדיקות (אין צורך בשום סקריפט חיצוני):

### דרך א': מתוך Visual Studio (מומלץ למתחילים)
1. קודם עשו **Build** לפתרון (`Ctrl + Shift + B` או בתפריט: `Build -> Build Solution`) כדי לוודא שאין שגיאות קומפילציה.
2. בתפריט העליון לחצו על **`Test -> Test Explorer`** (או קיצור `Ctrl + E, T`).
3. בחלונית **Test Explorer** שנפתחה, לחצו על הכפתור **`Run All Tests`** (סמל "הפעל הכול" ירוק בפינה השמאלית העליונה).
4. המתינו מספר שניות — כל הבדיקות ירוצו ותראו ליד כל אחת מהן סימן ירוק או אדום.

### דרך ב': משורת הפקודה (Terminal / PowerShell)
פתחו טרמינל בתיקיית הפתרון והריצו:
```powershell
dotnet build
dotnet test
```
> **הערה:** בפרויקט זה מוגדר `xunit.v3` עם `Microsoft.Testing.Platform`, ולכן גם הפקודה הבאה מריצה את כל הבדיקות ישירות:
> ```powershell
> dotnet run --project MauiGoogleMapSample.Tests/MauiGoogleMapSample.Tests.csproj
> ```

---

## 5. איך קוראים את תוצאות הבדיקות?

לאחר ההרצה, כל בדיקה תקבל אחד משני מצבים:

* **✅ Passed (ירוק):** כל שורות ה-`Assert` עברו בהצלחה! הקוד מתנהג בדיוק כפי שציפינו.
* **❌ Failed (אדום):** לפחות שורת `Assert` אחת נכשלה. לחצו על הבדיקה האדומה ב-Test Explorer ותראו בחלק התחתון:
  1. **Message (הודעת השגיאה):** מה ציפינו לקבל (`Expected`) לעומת מה שהקוד החזיר בפועל (`Actual`).  
     לדוגמה: `Assert.False() Failure — Expected: False, Actual: True`.
  2. **Stack Trace (מיקום השגיאה):** שם הקובץ ומספר השורה המדויק שבו ה-`Assert` נכשל — לחיצה על השורה תקפיץ אתכם ישירות לקוד.

> **טיפ לתיקון (Debugging):** אם בדיקה נכשלת ואתם לא מבינים למה, שימו **Breakpoint** (נקודה אדומה בצד השורה) בתוך המתודה, לחצו קליק ימני על הבדיקה ב-Test Explorer ובחרו **`Debug`** — כך תוכלו לעבור שורה אחר שורה ולראות את ערכי המשתנים!

---

## 6. איך מוסיפים בדיקה חדשה — צעד אחר צעד

נניח שהוספתם כלל חדש למחלקת `MapConfigurationValidator` ורוצים לוודא שהוא עובד:

1. **פתחו את קובץ הבדיקות המתאים** בתיקיית `MauiGoogleMapSample.Tests/` (למשל `MapConfigurationValidatorTests.cs`).
2. **הוסיפו מתודה חדשה בתוך המחלקה** עם התכונה `[Fact]` מעליה:
   ```csharp
   [Fact]
   public void ValidateApiKey_WhenMyNewCase_ReturnsExpectedResult()
   {
       // Arrange
       var validator = new MapConfigurationValidator();

       // Act
       MapConfigCheckResult result = validator.ValidateApiKey("קלט לבדיקה");

       // Assert
       Assert.False(result.IsValid);
   }
   ```
3. **שמרו את הקובץ** (`Ctrl + S`).
4. **בצעו Build והריצו ב-Test Explorer** (`Test -> Test Explorer -> Run All Tests`) או באמצעות `dotnet test`.
5. **ודאו שהבדיקה החדשה הופיעה ברשימה והפכה לירוקה (`Passed`)!**
