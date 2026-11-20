# שלב 1: תשתית, חבילות NuGet והרשאות Android למפות Google

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git (Branch):** `stage/01-setup-and-permissions`  
> **קהל יעד:** תלמידים מתחילים בפיתוח אפליקציות מובייל (.NET MAUI)

---

## 1. מה אנחנו בונים בשלב הזה ולמה זה חשוב?

לפני שאפשר להציג מפה על המסך או להוסיף עליה סיכות (`Pins`) של תחנות קפה, צריך לבנות את ה**תשתית** שמחברת בין אפליקציית .NET MAUI שלנו לבין שירותי המפות של מערכת ההפעלה Android (Google Maps SDK).

בשלב הזה נלמד וניישם 4 אבני יסוד:
1. **התקנת חבילת NuGet** — הוספת `Microsoft.Maui.Controls.Maps` לפרויקט.
2. **רישום פקד המפה באתחול** — קריאה ל-`.UseMauiMaps()` בתוך `MauiProgram.cs`.
3. **מנגנון ההרשאות ב-Android (`AndroidManifest.xml`)** — איך מערכת ההפעלה מגנה על פרטיות המשתמש ומה בדיוק אנחנו מצהירים.
4. **מפתח Google Maps API Key** — איך מזדהים מול שרתי Google כדי לקבל אריחי מפה, וכיצד מאמתים את תקינות המפתח בעזרת שירות נפרד (`MapConfigurationValidator`) ובדיקות יחידה (`xunit.v3`).

---

## 2. מהי חבילת NuGet ולמה מתקינים `Microsoft.Maui.Controls.Maps`?

כדי לשמור על אפליקציות קלות ומהירות, .NET MAUI אינה כוללת כברירת מחדל את כל היכולות המתקדמות (כמו מפות).  
**NuGet** היא חנות הספריות הרשמית של .NET. כאשר אנו מתקינים את `Microsoft.Maui.Controls.Maps`, אנחנו מוסיפים לפרויקט:
* את פקד ה-XAML בשם `Map`.
* את מחלקות הנתונים `Location`, `MapSpan`, `Pin`, `Polyline` ו-`Polygon`.
* את ה-Handlers הטבעיים שמתרגמים את פקד ה-`Map` ל-Google Maps באנדרואיד ול-Apple Maps ב-iOS.

בקובץ `MauiGoogleMapSample/MauiGoogleMapSample.csproj` נוסף:

```xml
<PackageReference Include="Microsoft.Maui.Controls.Maps" Version="$(MauiVersion)" />
```

---

## 3. אתחול המפות ב-`MauiProgram.cs`

הקובץ `MauiProgram.cs` הוא "חדר הבקרה" של האפליקציה — הוא רץ ראשון בעת ההפעלה ובונה את כל השירותים והפקדים.  
כדי שפקד ה-`Map` יעבוד, חובה לשרשר `.UseMauiMaps()` ל-`MauiAppBuilder`:

```csharp
var builder = MauiApp.CreateBuilder();
builder
    .UseMauiApp<App>()
    .UseMauiMaps()
    .ConfigureFonts(fonts =>
    {
        fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
        fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
    });
```

בנוסף, נשתמש בשיטת **Fluent Builder Extension Methods** (`RegisterServices`, `RegisterViewModels`, `RegisterViews`) כדי לשמור על `CreateMauiApp()` נקי ומאורגן:

```csharp
var builder = MauiApp.CreateBuilder();
builder
    .UseMauiApp<App>()
    .UseMauiMaps()
    .RegisterServices()
    .RegisterViewModels()
    .RegisterViews()
    .ConfigureFonts(fonts =>
    {
        fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
        fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
    });
```

וכל מתודת הרחבה אחראית על שכבה אחת בלבד ומחזירה את `builder` להמשך השרשור:

```csharp
private static MauiAppBuilder RegisterServices(this MauiAppBuilder builder)
{
    builder.Services.AddSingleton<IMapConfigurationValidator, MapConfigurationValidator>();
    return builder;
}

private static MauiAppBuilder RegisterViewModels(this MauiAppBuilder builder)
{
    builder.Services.AddTransient<SetupStatusViewModel>();
    return builder;
}

private static MauiAppBuilder RegisterViews(this MauiAppBuilder builder)
{
    builder.Services.AddTransient<MainPage>();
    return builder;
}
```

---

## 4. מנגנון ההרשאות באנדרואיד — מה מנהלים ואיפה?

מערכת ההפעלה **Android** בנויה סביב אבטחה ופרטיות. אפליקציה **אינה יכולה** להשתמש בחיישני המכשיר (כמו GPS, מצלמה או אינטרנט) ללא הצהרה מפורשת בקובץ:
`MauiGoogleMapSample/Platforms/Android/AndroidManifest.xml`

הקובץ `AndroidManifest.xml` הוא מעין **"תעודת הזהות"** של האפליקציה מול מערכת ההפעלה וחנות Google Play.

### אילו הרשאות הוספנו ומה תפקיד כל אחת?

| הרשאה (`uses-permission`) | רמת דיוק / תפקיד | למה אפליקציית CoffeeMap צריכה אותה? |
| :--- | :--- | :--- |
| `android.permission.INTERNET` | גישה לרשת האינטרנט | טעינת אריחי המפה משרתי Google Maps. |
| `android.permission.ACCESS_NETWORK_STATE` | בדיקת מצב חיבור רשת | לדעת אם יש אינטרנט זמין לפני טעינת מפה. |
| `android.permission.ACCESS_COARSE_LOCATION` | מיקום משוער (רמת שכונה/רחוב, Wi-Fi/סלולר) | הצגת אזור כללי של המשתמש תוך חיסכון בסוללה. |
| `android.permission.ACCESS_FINE_LOCATION` | מיקום מדויק (GPS לווייני, רמת מטרים) | איתור מדויק של תחנת הקפה הקרובה ביותר למשתמש. |

> **חשוב לדעת למתחילים:** הצהרה ב-`AndroidManifest.xml` היא רק **השלב הראשון** (הרשאה ברמת התקנה). עבור הרשאות רגישות כמו מיקום, Android דורשת גם **אישור בזמן ריצה** מהמשתמש (חלון קופץ "האם לאפשר לאפליקציה לגשת למיקום שלך?") — את זה ניישם בשלב 4.

---

## 5. הגדרת Google Maps API Key (צעד אחר צעד)

מפות Google הן שירות ענן. כדי שהאפליקציה תוכל להציג מפה חיה באנדרואיד, חייבים להגדיר מפתח זיהוי (`API Key`) בתוך תגית `<application>` בקובץ `AndroidManifest.xml`:

```xml
<application android:allowBackup="true" android:icon="@mipmap/appicon" android:roundIcon="@mipmap/appicon_round" android:supportsRtl="true">
    <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
</application>
```

### איך מנפיקים מפתח אמיתי ב-Google Cloud Console?
המדריך הרשמי של Google בעברית: [הגדרת מפתח API ל-Maps SDK for Android](https://developers.google.com/maps/documentation/android-sdk/get-api-key?hl=he)

1. היכנסו ל-[Google Cloud Console](https://console.cloud.google.com/) עם חשבון Google.
2. צרו פרויקט חדש בשם `CoffeeMap-MAUI`.
3. בתפריט הצד עברו ל-**APIs & Services -> Library**, חפשו **Maps SDK for Android** ולחצו **Enable**.
4. עברו ל-**APIs & Services -> Credentials**, לחצו **+ CREATE CREDENTIALS -> API key**.
5. העתיקו את המפתח שנוצר (מתחיל ב-`AIza...`) והדביקו אותו במקום `YOUR_GOOGLE_MAPS_API_KEY_HERE` בקובץ `AndroidManifest.xml`.
6. **כלל אבטחה קריטי — סכנת חשיפת API Key בקוד המקור:**
   * **לעולם אל תשמרו מפתח API אמיתי בתוך קוד C# (Hardcoded) ואל תעלו אותו ל-GitHub!**
   * בוטים אוטומטיים סורקים את GitHub מסביב לשעון ומאתרים מפתחות Google (`AIza...`) תוך שניות. חשיפת מפתח עלולה לגרום לשימוש זדוני במכסת ה-API שלכם, לחיובים כספיים בלתי צפויים בחשבון Google Cloud, ולחסימת האפליקציה.
   * בנוסף, מומלץ להגביל את המפתח ב-Google Cloud Console לפי **Package Name** ו-**SHA-1** של אפליקציית האנדרואיד שלכם.

---

## 5.1 שמירת ה-API Key באחסון המוצפן (`SecureStorage`) ושליפתו למסכים

ב-.NET MAUI קיים שירות מובנה בשם **`SecureStorage`** ששומר זוגות מפתח-ערך באופן **מוצפן על המכשיר** (באמצעות **Android KeyStore** באנדרואיד ו-**Keychain** ב-iOS).

כך אנו מיישמים זאת בפרויקט בצורה נקייה ובטוחה (`Services/SecureKeyStorageService.cs`):

```csharp
// שמירה מוצפנת על המכשיר (במסך ההגדרות - שלב 1)
await SecureStorage.Default.SetAsync("coffeemap_google_maps_api_key", apiKey.Trim());

// שליפה מכל מסך אחר באפליקציה (למשל בשלב 2 או בקריאות REST)
string? savedKey = await SecureStorage.Default.GetAsync("coffeemap_google_maps_api_key");

// מחיקה מהאחסון המוצפן
SecureStorage.Default.Remove("coffeemap_google_maps_api_key");
```

### הבדל טכני חשוב שכדאי להכיר: `SecureStorage` מול `AndroidManifest.xml`
* **פקד המפה הטבעי (`<maps:Map>` באנדרואיד):** קורא את `com.google.android.geo.API_KEY` מקובץ `AndroidManifest.xml` בזמן הפעלת האפליקציה (לפני שקוד ה-C# רץ). לכן ב-Git אנו שומרים רק `YOUR_GOOGLE_MAPS_API_KEY_HERE`, ומציבים מפתח אמיתי מקומית בלבד (בלי לעשות לו `commit`).
* **`SecureStorage` (אחסון מוצפן בזמן ריצה):** הוא הדרך הנכונה והמאובטחת לשמור מפתחות API וסודות שמוזנים בזמן ריצה (כמו מפתח ל-Google Places / Directions / Geocoding REST API או ל-Gemini AI), ולשלוף אותם בכל מסך אחר באפליקציה בלי לשמור אותם בקוד המקור!
* בדוגמה שלנו, `MainPage` מאפשר לשמור את המפתח ב-`SecureStorage`, ו-`MapDisplayPage` (שלב 2) מדגים שליפה שלו (והצגתו בצורה מוסתרת/Masked: `AIza••••9999`) מבלי לחשוף את המפתח המלא.

---

## 6. ארכיטקטורת Vanilla C# MVVM בדוגמה של שלב 1

כדי להדגים ארכיטקטורה נקייה כבר מהשלב הראשון, יצרנו מסך בדיקת תצורה (`MainPage`) שמפריד בין השכבות:

* **Service (`Services/MapConfigurationValidator.cs`)**: בודק האם מפתח API תקין (לא ריק, לא Placeholder, ובאורך מספק).
* **ViewModel (`ViewModels/SetupStatusViewModel.cs`)**: מממש `INotifyPropertyChanged` ו-`ICommand` (כולל `CanExecute` שמשבית את הכפתור כשהשדה ריק) ומציג למשתמש סטטוס ברור.
* **View (`MainPage.xaml`)**: דף XAML בעברית (`FlowDirection="RightToLeft"`) עם Compiled Bindings (`x:DataType="vm:SetupStatusViewModel"`).
* **Unit Tests (`MauiGoogleMapSample.Tests/`)**: בדיקות אוטומטיות ב-`xunit.v3` המאמתות את `MapConfigurationValidator` ואת `SetupStatusViewModel` ללא צורך באימולטור. להסבר מלא על הרצת בדיקות ב-Visual Studio וב-`dotnet test`, ראו את המדריך [`00-Working-With-Unit-Tests.pdf`](00-Working-With-Unit-Tests.pdf).

---

## סיכום שלב 1
* התקנו את `Microsoft.Maui.Controls.Maps` והפעלנו `.UseMauiMaps()`.
* הצהרנו על הרשאות מיקום ואינטרנט והגדרנו `com.google.android.geo.API_KEY` (עם Placeholder) ב-`AndroidManifest.xml`.
* הפרדנו את לוגיקת בדיקת המפתח ל-Service ו-ViewModel נבדקים.
* כעת אפשר לעבור למשימת התרגול בתיקיית `Docs/Assignments/01-Setup-And-Permissions-Assignment.pdf`!
