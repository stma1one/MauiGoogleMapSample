# משימה 1: הגדרת הרשאות, מפתח API והרחבת שירות האימות

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git בסיס:** `stage/01-setup-and-permissions`  
> **זמן משוער:** 30–40 דקות

---

## מטרת המשימה
לתרגל את הבנת מבנה קובץ ה-`AndroidManifest.xml`, מנגנון ההרשאות ב-Android, והרחבת לוגיקת האימות בשכבת ה-`Services` כולל כתיבת בדיקת יחידה ב-`xunit.v3`.

---

## חלק א': היכרות ובדיקת `AndroidManifest.xml` (מעשי)

1. פתחו את הקובץ `MauiGoogleMapSample/Platforms/Android/AndroidManifest.xml`.
2. אתרו את 4 שורות ה-`<uses-permission>` ואת תגית ה-`<meta-data>` של `com.google.android.geo.API_KEY`.
3. **שאלת בדיקה (כתבו לעצמכם במחברת/ב-`Learning/MAUI-Learning-Book.md`):**
   * מה ההבדל בין `ACCESS_COARSE_LOCATION` לבין `ACCESS_FINE_LOCATION`?
   * מדוע אסור להעלות מפתח API אמיתי ל-GitHub ציבורי?

---

## חלק ב': הרחבת `MapConfigurationValidator` (כתיבת קוד)

בדוגמה שראינו, `MapConfigurationValidator.ValidateApiKey` בודק רק שהמפתח:
1. אינו ריק.
2. אינו שווה ל-Placeholder (`YOUR_GOOGLE_MAPS_API_KEY_HERE`).
3. ארוך מ-20 תווים.

**המשימה שלכם:**
הוסיפו בדיקה נוספת בתוך `MauiGoogleMapSample/Services/MapConfigurationValidator.cs`:
1. בדקו האם המפתח מתחיל בקידומת התקנית של מפתחות Google API — המחרוזת `"AIza"` (באמצעות `trimmed.StartsWith("AIza", StringComparison.Ordinal)`).
2. אם המפתח **אינו** מתחיל ב-`"AIza"`, החזירו `MapConfigCheckResult` עם:
   * `IsValid = false`
   * `StatusTitle = "קידומת מפתח לא תקינה"`
   * `Details = "מפתח Google Maps API תקין חייב להתחיל בקידומת AIza."`

---

## חלק ג': הוספת בדיקת יחידה ב-`xunit.v3`

1. פתחו את הקובץ `MauiGoogleMapSample.Tests/MapConfigurationValidatorTests.cs`.
2. הוסיפו בדיקה חדשה בשם:
   `ValidateApiKey_WhenMissingAIzaPrefix_ReturnsInvalid`
3. השתמשו במבנה **Arrange – Act – Assert**:
   * **Arrange:** צרו מופע של `MapConfigurationValidator`.
   * **Act:** העבירו מחרוזת ארוכה מ-20 תווים שלא מתחילה ב-`AIza` (למשל `"ZZZZ12345678901234567890"`).
   * **Assert:** ודאו ש-`result.IsValid` הוא `false` וש-`result.StatusTitle` מכיל `"קידומת"`.
4. הריצו בטרמינל:
   ```powershell
   .\Scripts\Validate-Tests.ps1
   ```
   וודאו שכל הבדיקות עוברות (`Failed: 0`).

---

## חלק ד' (בונוס): הנפקת מפתח אמיתי לבדיקה מקומית
אם יש ברשותכם חשבון Google Cloud:
1. פעלו לפי המדריך ב-`Docs/01-Setup-And-Permissions.pdf` והנפיקו מפתח `Maps SDK for Android`.
2. בדקו את המפתח בתוך מסך `MainPage` של האפליקציה וראו שהסטטוס משתנה ל**"פורמט המפתח תקין"**.
3. **שימו לב:** אל תבצעו `git commit` עם המפתח האמיתי שלכם!
