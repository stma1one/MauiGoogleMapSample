# שלב 1: תשתית, חבילות NuGet והרשאות Android למפות Google

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git (Branch):** `stage/01-setup-and-permissions`  
> **קהל יעד:** תלמידים מתחילים בפיתוח אפליקציות מובייל (.NET MAUI)  
> **מקרא צבעים בקוד:** שורות המודגשות ב**רקע ירוק וטקסט צהוב** הן השורות המדויקות שעליכם **להוסיף** לפרויקט.

---

## 1. מה אנחנו בונים בשלב הזה ולמה זה חשוב?

לפני שאפשר להציג מפה על המסך או להוסיף עליה סיכות (`Pins`) של תחנות קפה, צריך לבנות את ה**תשתית** שמחברת בין אפליקציית .NET MAUI שלנו לבין שירותי המפות של מערכת ההפעלה Android (Google Maps SDK).

בשלב הזה נלמד וניישם 4 אבני יסוד:
1. **התקנת חבילת NuGet** — הוספת `Microsoft.Maui.Controls.Maps` לפרויקט (ב-Visual Studio 2026 או ב-JetBrains Rider ב-Mac).
2. **רישום פקד המפה באתחול** — קריאה ל-`.UseMauiMaps()` בתוך `MauiProgram.cs`.
3. **מנגנון ההרשאות והגדרת ה-API Key ב-Android (`AndroidManifest.xml`)** — איך מערכת ההפעלה מגנה על פרטיות המשתמש ואיפה בדיוק מציבים את המפתח.
4. **אבטחת מידע, `SecureStorage` וארכיטקטורת MVVM** — איך מגנים על המפתח ב-GitHub, איפה כותבים את הקוד של `SecureStorage`, ואיך בנויות השכבות.

---

## 2. מהי חבילת NuGet ואיך מתקינים את `Microsoft.Maui.Controls.Maps`?

כדי לשמור על אפליקציות קלות ומהירות, .NET MAUI אינה כוללת כברירת מחדל את כל היכולות המתקדמות (כמו מפות).  
**NuGet** היא חנות הספריות הרשמית של .NET. כאשר אנו מתקינים את `Microsoft.Maui.Controls.Maps`, אנחנו מוסיפים לפרויקט את פקד ה-`Map`, את מחלקות הנתונים (`Location`, `MapSpan`, `Pin`, `Polyline`, `Circle`) ואת ה-Handlers הטבעיים ל-Google Maps באנדרואיד ול-Apple Maps ב-iOS.

### התקנה ב-Visual Studio 2026 (Windows) — צעד אחר צעד:
1. בחלונית **Solution Explorer**, לחצו **קליק ימני** על פרויקט האפליקציה **`MauiGoogleMapSample`** (שימו לב: על הפרויקט עצמו, **לא** על ה-Solution ולא על פרויקט ה-`Tests`).
2. בחרו בתפריט: **`Manage NuGet Packages...`**.
3. בחלונית שנפתחה, עברו ללשונית **`Browse`** (חיפוש).
4. הקלידו בשורת החיפוש: `Microsoft.Maui.Controls.Maps`.
5. בחרו את החבילה הרשמית של **Microsoft**, בחרו בגרסה היציבה התואמת לגרסת ה-.NET MAUI שלכם, ולחצו **`Install`**.
6. אשרו את חלון הרישיון (**Accept**) והמתינו לסיום ההתקנה.

### התקנה ב-JetBrains Rider (macOS) — צעד אחר צעד:
1. פתחו את חלונית **`NuGet`** בתחתית המסך (או לחצו **קליק ימני** על פרויקט **`MauiGoogleMapSample`** בחלונית **Explorer** ובחרו **`Manage NuGet Packages`**).
2. בשורת החיפוש הקלידו: `Microsoft.Maui.Controls.Maps`.
3. לחצו על החבילה הרשמית של **Microsoft** ברשימת התוצאות.
4. בצד ימין של החלונית, ודאו שהפרויקט **`MauiGoogleMapSample`** מסומן (ולא פרויקט ה-`Tests`), בחרו את הגרסה היציבה התואמת ל-.NET 10, ולחצו על כפתור **`+` (Install)**.

### מה משתנה בקובץ `MauiGoogleMapSample.csproj` לאחר ההתקנה?

```xml
<ItemGroup>
    <PackageReference Include="Microsoft.Maui.Controls" Version="$(MauiVersion)" />
    <PackageReference Include="Microsoft.Extensions.Logging.Debug" Version="10.0.0" />
+   <PackageReference Include="Microsoft.Maui.Controls.Maps" Version="$(MauiVersion)" />
</ItemGroup>
```

---

## 3. אתחול המפות ורישום שכבות ב-`MauiProgram.cs`

הקובץ `MauiProgram.cs` הוא "חדר הבקרה" של האפליקציה — הוא רץ ראשון בעת ההפעלה ובונה את כל השירותים והפקדים.  
כדי שפקד ה-`Map` יעבוד, **חובה** לשרשר את **`.UseMauiMaps()`** ל-`MauiAppBuilder`.  
בנוסף, אנו משתמשים בשיטת **Fluent Builder Extension Methods** (`RegisterServices`, `RegisterViewModels`, `RegisterViews`) כדי לשמור על `CreateMauiApp()` נקי ומאורגן:

```csharp
var builder = MauiApp.CreateBuilder();
builder
    .UseMauiApp<App>()
+   .UseMauiMaps()
+   .RegisterServices()
+   .RegisterViewModels()
+   .RegisterViews()
    .ConfigureFonts(fonts =>
    {
        fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
        fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
    });
```

> **שימו לב — הבהרה חשובה למתחילים!**  
> בקטע הקוד למטה מופיעים שירותים כמו `IMapConfigurationValidator`, `MapConfigurationValidator`, `ISecureKeyStorageService`, `SecureKeyStorageService`, ו-`SetupStatusViewModel`.  
> **אלו אינם שירותים מובנים של .NET MAUI או של Google!**  
> אלו מחלקות **שאנחנו יצרנו בעצמנו** בתוך הפרויקט הזה (בתיקיות `Services/` ו-`ViewModels/`).  
> אם תפתחו פרויקט MAUI חדש משלכם — **השורה היחידה שמגיעה מ-.NET MAUI להפעלת מפות היא `.UseMauiMaps()`**, ובתוך `RegisterServices` / `RegisterViewModels` / `RegisterViews` תרשמו אך ורק את המחלקות שאתם תכתבו בפרויקט שלכם!

| רכיב ב-`MauiProgram.cs` | מאיפה הוא מגיע? | תפקיד |
| :--- | :--- | :--- |
| `.UseMauiMaps()` | **מובנה בחבילת `Microsoft.Maui.Controls.Maps`** | מחבר את פקד ה-`Map` למפות Google באנדרואיד / Apple Maps ב-iOS. |
| `IMapConfigurationValidator` / `MapConfigurationValidator` | **מחלקה שכתבנו בעצמנו** (`Services/`) | בודקת תקינות פורמט של מפתח API. |
| `ISecureKeyStorageService` / `SecureKeyStorageService` | **מחלקה שכתבנו בעצמנו** (`Services/`) | עוטפת את `SecureStorage.Default` המובנה של MAUI לשמירת מפתח מוצפן. |
| `SetupStatusViewModel` | **מחלקה שכתבנו בעצמנו** (`ViewModels/`) | ה-ViewModel של מסך שלב 1 (`MainPage`). |

```csharp
+ private static MauiAppBuilder RegisterServices(this MauiAppBuilder builder)
+ {
+     builder.Services.AddSingleton<IMapConfigurationValidator, MapConfigurationValidator>();
+     builder.Services.AddSingleton<ISecureKeyStorageService, SecureKeyStorageService>();
+     return builder;
+ }
+
+ private static MauiAppBuilder RegisterViewModels(this MauiAppBuilder builder)
+ {
+     builder.Services.AddTransient<SetupStatusViewModel>();
+     return builder;
+ }
+
+ private static MauiAppBuilder RegisterViews(this MauiAppBuilder builder)
+ {
+     builder.Services.AddTransient<MainPage>();
+     return builder;
+ }
```

---

## 4. מנגנון ההרשאות באנדרואיד — מה מנהלים ואיפה?

מערכת ההפעלה **Android** בנויה סביב אבטחה ופרטיות. אפליקציה **אינה יכולה** להשתמש בחיישני המכשיר (כמו GPS או אינטרנט) ללא הצהרה מפורשת בקובץ:
`MauiGoogleMapSample/Platforms/Android/AndroidManifest.xml`

הקובץ `AndroidManifest.xml` הוא **"תעודת הזהות"** של האפליקציה מול מערכת ההפעלה וחנות Google Play.

### אילו הרשאות יש להוסיף?

| הרשאה (`uses-permission`) | רמת דיוק / תפקיד | למה אפליקציית CoffeeMap צריכה אותה? |
| :--- | :--- | :--- |
| `android.permission.INTERNET` | גישה לרשת האינטרנט | טעינת אריחי המפה משרתי Google Maps. |
| `android.permission.ACCESS_NETWORK_STATE` | בדיקת מצב חיבור רשת | לדעת אם יש אינטרנט זמין לפני טעינת מפה. |
| `android.permission.ACCESS_COARSE_LOCATION` | מיקום משוער (רמת שכונה/רחוב, Wi-Fi/סלולר) | הצגת אזור כללי של המשתמש תוך חיסכון בסוללה. |
| `android.permission.ACCESS_FINE_LOCATION` | מיקום מדויק (GPS לווייני, רמת מטרים) | איתור מדויק של תחנת הקפה הקרובה ביותר למשתמש. |

<div class="alert-important">
<strong>🔑 חובה לשים לב — תגית <code>com.google.android.geo.API_KEY</code>!</strong><br/>
מלבד ההרשאות, <strong>בתוך תגית <code>&lt;application&gt;...&lt;/application&gt;</code></strong> בקובץ <code>AndroidManifest.xml</code> יש להוסיף תגית <code>&lt;meta-data&gt;</code> עם השם המדויק <strong><code>com.google.android.geo.API_KEY</code></strong>.<br/>
<strong>זהו המקום המדויק שבו יש להציב את מפתח ה-Google Maps API שלכם</strong> (במקום הערך <code>YOUR_GOOGLE_MAPS_API_KEY_HERE</code>). ללא שורה זו, המפה באנדרואיד תוצג ריקה/אפורה או תיכשל בטעינה!
</div>

### השורות שיש להוסיף ב-`Platforms/Android/AndroidManifest.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
+   <application android:allowBackup="false" android:icon="@mipmap/appicon" android:roundIcon="@mipmap/appicon_round" android:supportsRtl="true">
+       <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
    </application>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.INTERNET" />
+   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
+   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
</manifest>
```

> **חשוב לדעת למתחילים:** הצהרה ב-`AndroidManifest.xml` היא רק **השלב הראשון** (הרשאה ברמת התקנה). עבור הרשאות רגישות כמו מיקום, Android דורשת גם **אישור בזמן ריצה** מהמשתמש (חלון קופץ "האם לאפשר לאפליקציה לגשת למיקום שלך?") — את זה ניישם בשלב 4.

---

## 5. הנפקת Google Maps API Key והגנה על המפתח ב-GitHub

### איך מנפיקים מפתח אמיתי ב-Google Cloud Console?
המדריך הרשמי של Google בעברית: [הגדרת מפתח API ל-Maps SDK for Android](https://developers.google.com/maps/documentation/android-sdk/get-api-key?hl=he)

1. היכנסו ל-[Google Cloud Console](https://console.cloud.google.com/) עם חשבון Google.
2. צרו פרויקט חדש בשם `CoffeeMap-MAUI`.
3. בתפריט הצד עברו ל-**APIs & Services -> Library**, חפשו **Maps SDK for Android** ולחצו **Enable**.
4. עברו ל-**APIs & Services -> Credentials**, לחצו **+ CREATE CREDENTIALS -> API key**, והעתיקו את המפתח (מתחיל ב-`AIza...`).

<div class="alert-security">
<strong>🚨 סכנת חשיפת API Key ב-GitHub — למה אסור להעלות מפתח אמיתי?</strong><br/>
בוטים אוטומטיים סורקים את GitHub מסביב לשעון ומאתרים מפתחות Google (<code>AIza...</code>) תוך שניות. חשיפת מפתח עלולה לגרום לניצול המכסה שלכם, לחיובים כספיים בלתי צפויים בחשבון Google Cloud ולחסימת האפליקציה. בנוסף, תמיד הגבילו את המפתח ב-Google Cloud לפי <strong>Package Name</strong> ו-<strong>SHA-1</strong> של האפליקציה.
</div>

### שאלות נפוצות של תלמידים:

#### 1. האם אפשר להעביר ל-`AndroidManifest.xml` את המפתח מתוך `SecureStorage`?
**לא.** קובץ `AndroidManifest.xml` נארז באופן סטטי לתוך קובץ ה-APK **בזמן הבנייה (Compile Time)**, ומנוע Google Maps של Android קורא ממנו את `com.google.android.geo.API_KEY` בזמן עליית האפליקציה — עוד לפני שקוד ה-C# של `SecureStorage` בכלל רץ.

#### 2. אז איך מגנים על המפתח כשמעלים ל-GitHub — האם צריך למחוק אותו בכל פעם לפני `git push`?
**לא חייבים למחוק ידנית בכל פעם!** יש שתי דרכים לעבוד בצורה בטוחה:
* **הדרך הפשוטה לכיתה (הגנה ב-Google Cloud + אי-שמירה ב-Commit):** משאירים את `AndroidManifest.xml` עם Placeholder ב-Git, וכאשר מדביקים מפתח אמיתי לבדיקה מקומית — לא מסמנים את `AndroidManifest.xml` ב-`git commit`, ומוודאים שהמפתח מוגבל ב-Google Cloud Console לפי `Package Name` ו-`SHA-1` (כך גם אם מישהו יראה אותו, הוא לא יעבוד באפליקציה אחרת).
* **הדרך המקצועית (אוטומטית עם `.gitignore`):** יוצרים קובץ מקומי בשם `Secrets.props` ומוסיפים אותו ל-`.gitignore` (כך שלעולם לא יעלה ל-GitHub), ומזריקים ממנו את המפתח בזמן בנייה באמצעות MSBuild (`ManifestPlaceholders`). כך הקוד ב-GitHub נשאר נקי לתמיד בלי למחוק כלום!

---

## 5.1 שמירת מפתח ב-`SecureStorage` המוצפן — באיזו מחלקה כותבים מה?

עבור מפתחות שמשמשים אותנו **בזמן ריצה** (כמו קריאות ל-Google Places / Directions / Geocoding REST API או ל-Gemini AI), שומרים את המפתח באחסון המוצפן של המכשיר (**`SecureStorage`** — Android KeyStore / iOS Keychain).

**באיזו מחלקה רושמים כל חלק של הקוד?**

| פעולה | קובץ ומחלקה מדויקת בפרויקט | תפקיד |
| :--- | :--- | :--- |
| **שמירה / קריאה / מחיקה ב-`SecureStorage`** | `Services/SecureKeyStorageService.cs` (ממשק: `ISecureKeyStorageService`) | שכבת השירות היחידה שמדברת עם `SecureStorage.Default`. כך שאר הקוד נשאר נקי וניתן לבדיקה ב-Unit Tests! |
| **שמירת המפתח שהמשתמש הזין במסך** | `ViewModels/SetupStatusViewModel.cs` (`ExecuteSaveKeyAsync`, `LoadSavedKeyAsync`) | מקבל את `ISecureKeyStorageService` בבנאי (DI), שומר את המפתח וטוען אותו ב-`MainPage.OnAppearing()`. |
| **שליפת המפתח במסך אחר** | `ViewModels/MapDisplayViewModel.cs` (`LoadStoredKeyStatusAsync`) | מקבל את אותו `ISecureKeyStorageService` ב-DI ושולף את המפתח המוצפן (ומציג אותו מוסתר: `AIza••••9999`). |

קטע הקוד המלא בתוך **`Services/SecureKeyStorageService.cs`**:

```csharp
using Microsoft.Maui.Storage;

namespace MauiGoogleMapSample.Services;

public class SecureKeyStorageService : ISecureKeyStorageService
{
    private const string GoogleMapsApiKeyStorageKey = "coffeemap_google_maps_api_key";

    public async Task SaveApiKeyAsync(string apiKey)
    {
+       await SecureStorage.Default.SetAsync(GoogleMapsApiKeyStorageKey, apiKey.Trim());
    }

    public async Task<string?> GetApiKeyAsync()
    {
+       return await SecureStorage.Default.GetAsync(GoogleMapsApiKeyStorageKey);
    }

    public void ClearApiKey()
    {
+       SecureStorage.Default.Remove(GoogleMapsApiKeyStorageKey);
    }
}
```

---

## 6. ארכיטקטורת MVVM ומבנה קוד אימות הקונפיגורציה

כדי שהאפליקציה תהיה מסודרת, קריאה וניתנת לבדיקה אוטומטית (Unit Tests), אנו מפרידים את הקוד ל-4 שכבות ברורות (**Vanilla C# MVVM**):

<div class="mvvm-box">
<strong>תרשים שכבות MVVM בשלב 1 (מוזרק דרך <code>MauiProgram.cs</code>):</strong>
<div class="mvvm-flow">
  <div class="mvvm-layer mvvm-view">
    <strong>View (תצוגה)</strong><br/>
    <code>MainPage.xaml</code><br/>
    שדה קלט, כפתורים וטקסטים.<br/>
    מתחבר ב-<code>Binding</code> בלבד.
  </div>
  <div class="mvvm-arrow">⇄</div>
  <div class="mvvm-layer mvvm-vm">
    <strong>ViewModel (מצב ופקודות)</strong><br/>
    <code>SetupStatusViewModel.cs</code><br/>
    <code>INotifyPropertyChanged</code><br/>
    <code>ICommand</code> + <code>CanExecute</code>
  </div>
  <div class="mvvm-arrow">→</div>
  <div class="mvvm-layer mvvm-svc">
    <strong>Services (לוגיקה ונתונים)</strong><br/>
    <code>MapConfigurationValidator.cs</code><br/>
    <code>SecureKeyStorageService.cs</code><br/>
    בדיקות תקינות וגישה לאחסון.
  </div>
  <div class="mvvm-arrow">→</div>
  <div class="mvvm-layer mvvm-plat">
    <strong>Platform / OS</strong><br/>
    <code>AndroidManifest.xml</code><br/>
    <code>SecureStorage.Default</code><br/>
    הרשאות ומפתח מוצפן.
  </div>
</div>
</div>

### הסבר על קובץ אימות הקונפיגורציה (`Services/MapConfigurationValidator.cs`)

כדי לעזור לתלמידים ולמשתמש לזהות מיד האם מפתח ה-API הוגדר כראוי, יצרנו את המחלקה `MapConfigurationValidator` ואת טיפוס התוצאה `MapConfigCheckResult(bool IsValid, string StatusTitle, string Details)`.

המתודה `ValidateApiKey(string? apiKey)` מבצעת **3 בדיקות מדורגות**:
1. **מפתח ריק או רווחים (`string.IsNullOrWhiteSpace`):** מחזירה `IsValid = false` עם הכותרת `"מפתח API חסר"`.
2. **עדיין מוגדר Placeholder (`YOUR_GOOGLE_MAPS_API_KEY_HERE`):** מחזירה `IsValid = false` ומזכירה שצריך להחליפו במפתח מ-Google Cloud Console.
3. **אורך קצר מדי (`trimmed.Length < 20`):** מחזירה `IsValid = false` כי מפתחות Google אמיתיים ארוכים מ-20 תווים.
4. **אחרת:** מחזירה `IsValid = true` (`"פורמט המפתח תקין"`), מה שמפעיל אוטומטית את כפתור `"שמור מוצפן"` דרך `SaveKeyCommand.CanExecute`!

```csharp
public MapConfigCheckResult ValidateApiKey(string? apiKey)
{
    if (string.IsNullOrWhiteSpace(apiKey))
        return new MapConfigCheckResult(false, "מפתח API חסר", "...");

    string trimmed = apiKey.Trim();
    if (string.Equals(trimmed, PlaceholderKey, StringComparison.OrdinalIgnoreCase))
        return new MapConfigCheckResult(false, "מוגדר מפתח Placeholder", "...");

    if (trimmed.Length < 20)
        return new MapConfigCheckResult(false, "פורמט מפתח קצר מדי", "...");

    return new MapConfigCheckResult(true, "פורמט המפתח תקין", "...");
}
```

### דיאגרמות מערכת ובדיקות יחידה
* בתיקיית `Docs/` מחכים לכם גם קובצי PDF של הדיאגרמות המלאות של הפרויקט:
  * [`Architecture-Overview.pdf`](Architecture-Overview.pdf) — ארכיטקטורה כללית
  * [`Architecture-UML.pdf`](Architecture-UML.pdf) — דיאגרמת מחלקות (UML)
  * [`Screen-Flow.pdf`](Screen-Flow.pdf) — תרשים זרימת מסכים
* להסבר מלא על הרצת בדיקות היחידה ב-Visual Studio וב-`dotnet test`, ראו [`00-Working-With-Unit-Tests.pdf`](00-Working-With-Unit-Tests.pdf).
* למשימת התרגול שלכם, פתחו את [`Assignments/01-Setup-And-Permissions-Assignment.pdf`](Assignments/01-Setup-And-Permissions-Assignment.pdf)!
