# תיעוד בדיקות יחידה (xUnit Test Documentation) — הכנה להגנה על הפרויקט

מסמך זה מרכז את כל בדיקות היחידה (`xUnit`) בפרויקט `<AppName>.Tests`.
הוא מתעד מה כל בדיקה מאמתת לפי תבנית **Arrange – Act – Assert (AAA)**, אילו רכיבי לוגיקה (`ViewModels`, `Services`, `Converters`, `Models`) מכוסים, ואיך להסביר כל בדיקה לבוחן בבחינה בעל-פה (25% "שליטה בקוד").

> **מדיניות ניהול בדיקות (`.agents/MAUI-Agent-Mode.json`):**
> - `includeTests`: קובע האם הפרויקט כולל ומאמת בדיקות יחידה (`true` כברירת מחדל). אם מוגדר `false`, מתעלמים מההגדרה של מי כותב את הבדיקות.
> - `testManagementMode` (כאשר `includeTests: true` ו-`studentCapabilityMode: true`):
>   - `"combined"` (משולב — ברירת מחדל): הסוכן יוצר ומסביר בסוף כל שלב את הבדיקות שנוצרו, ומציע לתלמיד לכתוב חלק מהבדיקות.
>   - `"agent"` (סוכן): הסוכן כותב ומריץ את הבדיקות באופן עצמאי כחלק מהתהליך ומתעד אותן כאן.
>   - `"student"` (תלמיד): הסוכן מנחה את התלמיד בכתיבת הבדיקות ומנהל שיח כדי לוודא שהתלמיד מבין אילו מקרי קצה ובדיקות נדרשים.
> - **במצב `MAXIMIZE CODE GENERATED` (`studentCapabilityMode: false`):** כאשר `includeTests: true`, הסוכן **תמיד** כותב ומריץ את הבדיקות בעצמו (ללא תלות ב-`testManagementMode`) ומעדכן מסמך זה עבור כל רכיב לוגיקה חדש (`ViewModel` / `Service` / `Converter`).

---

## 1. טבלת ריכוז בדיקות היחידה בפרויקט (`<AppName>.Tests`)

בכל סלייס שבו נוספת או מתעדכנת לוגיקה (`ViewModel`, `Service`, `Converter`), יש להוסיף שורה לטבלה זו:

| # | מחלקת הבדיקה (`Test Class`) | שם הבדיקה (`Test Method`) | הרכיב הנבדק (`Target Component`) | מי כתב? (`Agent` / `Student` / `Combined`) | תרחיש הבדיקה (`Arrange -> Act -> Assert`) | מה להסביר לבוחן בבחינה בעל-פה? |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `ArchitectureSmokeTests` | `TestHarness_WhenInitialized_PassesSanityCheck` | `<AppName>.Tests` | `Agent` | **Arrange:** הגדרת ערכי בסיס. **Act:** הרצת בדיקת שפיות. **Assert:** אימות שתשתית `xUnit` פעילה ומקושרת לפרויקט. | כיצד פרויקט ה-`xUnit` מקושר לפרויקט ה-MAUI באמצעות יעד `net10.0` / `net11.0` ומאפשר הרצת בדיקות לוגיקה מהירות ללא אמולטור. |

---

## 2. פירוט הבדיקות לפי תבנית Arrange – Act – Assert (AAA)

### הסבר עקרון AAA לתלמיד ולבוחן:
1. **Arrange (הכנה):** יצירת המופעים הנדרשים לבדיקה (למשל `FakeDatabaseService` או `ViewModel` עם נתוני דמה) ללא תלות במסך XAML אמיתי או במסד נתונים חיצוני.
2. **Act (פעולה):** הפעלת המתודה או ה-`Command` שאותם רוצים לבדוק (למשל `vm.SaveCommand.Execute(null)` או `await vm.InitializeAsync()`).
3. **Assert (אימות):** בדיקה שהתוצאה בפועל תואמת לתוצאה המצופה (`Assert.True`, `Assert.Equal`, בדיקת `CanExecute`, בדיקת `IsLoading` או הודעת שגיאה).

### הנחיה לבדיקת שירותי AI (`Google.GenAI` — https://googleapis.github.io/dotnet-genai/):
- בבדיקות יחידה (`xunit.v3`) **אין לבצע קריאות רשת חיות** לשרתי Google Gemini.
- מומלץ לבדוק שני היבטים:
  1. **בדיקת ה-`ViewModel` מול `FakeAiService` (המממש את ממשק ה-Service):** אימות ש-`IsLoading`, `CanExecute`, עדכון ה-`ObservableCollection` וטיפול בשגיאות פועלים כשורה.
  2. **בדיקת פענוח הפלט המובנה (`ParseStructuredResponse`):** הפרדת פענוח ה-JSON (`JsonSerializer.Deserialize<T>`) למתודה עצמאית במחלקת ה-AI Service ובדיקתה מול מחרוזת JSON תקינה, מחרוזת ריקה ו-JSON שגוי.

