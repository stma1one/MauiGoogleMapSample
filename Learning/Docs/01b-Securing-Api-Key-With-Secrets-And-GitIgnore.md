# מדריך מיוחד למתחילים: שמירת API Key בקובץ מקומי, הזרקה אוטומטית ועבודה עם `.gitignore`

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **קהל יעד:** תלמידים שנתקלים לראשונה בקובץ `.gitignore`, קובצי תצורה מקומיים והזרקת משתנים ל-`AndroidManifest.xml`.  
> **מקרא צבעים בקוד:** שורות המודגשות ב**רקע ירוק וטקסט צהוב** הן השורות המדויקות שעליכם **להוסיף**.

---

## 1. מה הבעיה? למה אסור להדביק API Key ישירות בקוד או ב-`AndroidManifest.xml`?

כאשר אתם מנפיקים מפתח Google Maps API (`AIza...`), המפתח הזה מקושר לחשבון Google Cloud שלכם.  
אם תדביקו אותו ישירות בתוך `AndroidManifest.xml` ותעלו את הפרויקט ל-GitHub:
* **בוטים אוטומטיים** סורקים את כל המאגרים הציבוריים ב-GitHub 24/7 ומזהים מפתחות `AIza...` תוך שניות.
* תוקפים עלולים לנצל את המפתח שלכם באפליקציות שלהם, לחרוג מהמכסה החינמית, לגרום לחיובים כספיים או לחסימת האפליקציה שלכם.
* **ומה עם למחוק את המפתח ידנית לפני כל `git push`?** זו שיטה מסוכנת — מספיק ששוכחים פעם אחת, והמפתח נשמר לצמיתות בהיסטוריית ה-Git!

### הפתרון המקצועי (והפשוט!):
נפריד את המפתח לקובץ מקומי פרטי בשם **`Secrets.props`** שנשאר **אך ורק על המחשב שלכם**, נחסום אותו מהעלאה ל-GitHub באמצעות **`.gitignore`**, ונגרום ל-.NET **להזריק אותו אוטומטית** אל תוך `AndroidManifest.xml` בכל פעם שבונים את האפליקציה!

---

## 2. מה זה קובץ `.gitignore`? (הסבר מהיסוד)

כאשר עובדים עם Git ו-GitHub, יש קבצים בפרויקט שאנחנו **רוצים** לשתף עם חברי הצוות והמורה (קוד C#, קובצי XAML, תמונות), ויש קבצים שאנחנו **לא רוצים** שיעלו לעולם:
* תיקיות בנייה זמניות (`bin/`, `obj/`)
* הגדרות אישיות של Visual Studio (`.vs/`, `*.user`)
* **קובצי סודות ומפתחות API (`Secrets.props`)**

**`.gitignore`** הוא קובץ טקסט פשוט שנמצא בתיקיית השורש של הפרויקט (ליד קובץ ה-`.sln` / `.slnx`).  
כל שם קובץ או תיקייה שרשומים בתוך `.gitignore` הופכים ל**"שקופים" עבור Git** — Git מתעלם מהם לחלוטין, לא מציג אותם ברשימת השינויים, ולא מעלה אותם ל-GitHub אף פעם!

---

## 3. איך עובד מנגנון ההזרקה האוטומטית? (תרשים זרימה)

<div class="mvvm-box">
<strong>איך המפתח מגיע מהמחשב שלכם אל האפליקציה בלי לעלות ל-GitHub?</strong>
<div class="mvvm-flow">
  <div class="mvvm-layer mvvm-svc">
    <strong>1. קובץ מקומי פרטי</strong><br/>
    <code>Secrets.props</code><br/>
    מכיל את המפתח האמיתי.<br/>
    <strong>חסום ב-<code>.gitignore</code>!</strong>
  </div>
  <div class="mvvm-arrow">→</div>
  <div class="mvvm-layer mvvm-vm">
    <strong>2. קובץ הפרויקט (MSBuild)</strong><br/>
    <code>MauiGoogleMapSample.csproj</code><br/>
    טוען את <code>Secrets.props</code><br/>
    ומגדיר <code>AndroidManifestPlaceholders</code>
  </div>
  <div class="mvvm-arrow">→</div>
  <div class="mvvm-layer mvvm-view">
    <strong>3. המניפסט באנדרואיד</strong><br/>
    <code>AndroidManifest.xml</code><br/>
    מכיל רק משתנה:<br/>
    <code>${GoogleMapsApiKey}</code>
  </div>
  <div class="mvvm-arrow">→</div>
  <div class="mvvm-layer mvvm-plat">
    <strong>4. קובץ ה-APK במכשיר</strong><br/>
    בזמן Build, המשתנה<br/>
    מוחלף אוטומטית במפתח<br/>
    והמפה עובדת!
  </div>
</div>
</div>

**ומה קורה כשחבר צוות או המורה מורידים את הפרויקט מ-GitHub ואין להם עדיין `Secrets.props`?**  
הגדרנו בקובץ ה-`.csproj` ערך ברירת מחדל (`YOUR_GOOGLE_MAPS_API_KEY_HERE`) — כך שהפרויקט **תמיד מתקמפל ללא שגיאות** גם בלי הקובץ המקומי!

---

## 4. מדריך הגדרה צעד אחר צעד

### שלב א': חסימת `Secrets.props` בקובץ `.gitignore`
פתחו את הקובץ `.gitignore` בתיקיית השורש של הפרויקט וודאו שהשורות הבאות קיימות בו:

```gitignore
# Build outputs
bin/
obj/

# Local API keys & secrets (NEVER commit to Git!)
+ Secrets.props
+ **/Secrets.props
```

> **טיפ חשוב:** תמיד מוסיפים ל-`.gitignore` **לפני** שיוצרים את הקובץ `Secrets.props`!

---

### שלב ב': יצירת תבנית דוגמה (`Secrets.props.example`) שעולה ל-GitHub
כדי שכל חבר צוות יידע איך הקובץ המקומי צריך להיראות, יצרנו בתוך תיקיית `MauiGoogleMapSample/` קובץ דוגמה בשם `Secrets.props.example` (ש**כן** עולה ל-GitHub כי הוא מכיל רק Placeholder):

```xml
<Project>
  <PropertyGroup>
    <GoogleMapsApiKey>YOUR_GOOGLE_MAPS_API_KEY_HERE</GoogleMapsApiKey>
  </PropertyGroup>
</Project>
```

---

### שלב ג': יצירת הקובץ המקומי `Secrets.props` אצלכם במחשב

* **ב-Visual Studio 2026 (Windows):**
  1. ב-**Solution Explorer**, אתרו את הקובץ `Secrets.props.example` בתוך פרויקט `MauiGoogleMapSample`.
  2. לחצו עליו **Copy** (`Ctrl+C`) ואז **Paste** (`Ctrl+V`) על תיקיית פרויקט `MauiGoogleMapSample`.
  3. שנו את שם העותק ל-**`Secrets.props`** (בלי הסיומת `.example`).
  4. פתחו את `Secrets.props` והחליפו את `YOUR_GOOGLE_MAPS_API_KEY_HERE` במפתח האמיתי שלכם מ-Google Cloud Console.
* **ב-JetBrains Rider (macOS):**
  1. בחלונית **Explorer**, בחרו את `Secrets.props.example` בתוך `MauiGoogleMapSample`.
  2. לחצו `Cmd+C` ואז `Cmd+V` (או קליק ימני -> `Refactor / Copy`) ושמרו בשם **`Secrets.props`**.
  3. פתחו את `Secrets.props` והדביקו את המפתח האמיתי שלכם.

```xml
<Project>
  <PropertyGroup>
+   <GoogleMapsApiKey>AIzaSy...המפתח_האמיתי_שלכם_כאן...</GoogleMapsApiKey>
  </PropertyGroup>
</Project>
```

---

### שלב ד': חיבור הקובץ וההזרקה בתוך `MauiGoogleMapSample.csproj`
פתחו את `MauiGoogleMapSample/MauiGoogleMapSample.csproj` (קליק ימני על הפרויקט -> `Edit Project File`) וודאו שהשורות הבאות קיימות לפני `</Project>`:

```xml
+ <!-- טוען את המפתח האמיתי מהקובץ המקומי Secrets.props רק אם הוא קיים -->
+ <Import Project="Secrets.props" Condition="Exists('Secrets.props')" />
+
+ <PropertyGroup>
+   <!-- ערך ברירת מחדל אם הקובץ המקומי לא קיים, כדי שהפרויקט תמיד יתקמפל -->
+   <GoogleMapsApiKey Condition="'$(GoogleMapsApiKey)' == ''">YOUR_GOOGLE_MAPS_API_KEY_HERE</GoogleMapsApiKey>
+   <!-- מזריק את המפתח לתוך ${GoogleMapsApiKey} בקובץ AndroidManifest.xml בזמן Build -->
+   <AndroidManifestPlaceholders>GoogleMapsApiKey=$(GoogleMapsApiKey)</AndroidManifestPlaceholders>
+ </PropertyGroup>
```

---

### שלב ה': שימוש במשתנה המוזרק ב-`AndroidManifest.xml`
בקובץ `MauiGoogleMapSample/Platforms/Android/AndroidManifest.xml`, במקום לכתוב את המפתח עצמו, כותבים את המשתנה **`${GoogleMapsApiKey}`**:

```xml
<application android:allowBackup="true" android:icon="@mipmap/appicon" android:roundIcon="@mipmap/appicon_round" android:supportsRtl="true">
+   <meta-data android:name="com.google.android.geo.API_KEY" android:value="${GoogleMapsApiKey}" />
</application>
```

בזמן שתריצו **Build / Run** על אנדרואיד, מנוע הבנייה של .NET מחליף אוטומטית את `${GoogleMapsApiKey}` במפתח מתוך `Secrets.props` שלכם!

---

## 5. בדיקת בטיחות חובה לפני כל `git push`!

איך תדעו ב-100% ש-`Secrets.props` באמת לא עומד לעלות ל-GitHub?

1. **ב-Visual Studio 2026:** פתחו את חלונית **`Git Changes`** — ודאו ש-`Secrets.props` **אינו מופיע** ברשימת `Changes`!
2. **ב-JetBrains Rider:** פתחו את חלונית **`Commit`** (`Cmd+0`) — ודאו ש-`Secrets.props` **אינו מופיע** תחת `Unversioned Files` או `Changes`!
3. **בטרמינל (הבדיקה המהירה ביותר):** הריצו:
   ```powershell
   git status
   ```
   אם `Secrets.props` **לא מופיע בכלל בפלט** — ההגנה עובדת מצוין!

---

## 6. "ערכת חירום": מה עושים אם בטעות כבר העליתם מפתח ל-GitHub?

אל תיכנסו ללחץ, אבל פעלו מיד (מחיקת השורה ב-Commit חדש **אינה מספיקה** כי היסטוריית Git שומרת את הקוד הישן!):
1. היכנסו מיד ל-[Google Cloud Console -> Credentials](https://console.cloud.google.com/apis/credentials).
2. לחצו על המפתח שנחשף ובחרו **Delete** (או **Regenerate / Restrict**).
3. צרו מפתח חדש והציבו אותו **רק** בתוך `Secrets.props` המקומי שלכם (שחסום ב-`.gitignore`).
4. אל תשכחו להגביל את המפתח החדש לפי **`Package Name`** ו-**`SHA-1`** של האפליקציה שלכם!
