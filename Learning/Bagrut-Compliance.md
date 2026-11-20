# טבלת תכולות ובקרת עמידה בדרישות פרויקט גמר 5 יח"ל (חלופת טלפונים חכמים — 883589)

קובץ זה מרכז את עמידת הפרויקט בדרישות החובה והבחירה של משרד החינוך, ומשמש גם כבסיס הישיר לפרק **"טבלת תכולות הפרויקט"** בתיק הפרויקט.
- במהלך השנה: סמנו `PLANNED` על כל סעיף שנבחר לתוכנית העבודה של הפרויקט.
- לאחר מימוש בקוד: עדכנו מ-`PLANNED` ל-`IMPLEMENTED` וציינו בעמודת המימוש את שם הקובץ והמחלקה המדויקים.
- לקראת הגשה סופית: כל הסעיפים שנבחרו חייבים להיות במצב `IMPLEMENTED` (ניתן לאמת באמצעות הרצת `Validate-Bagrut-Compliance` עם דגל `-SubmissionReady` / `--submission-ready`).

## 1. פרטי דף השער (Cover Page Metadata)

```text
School Name (שם בית הספר): [TBD]
Institution Code (סמל מוסד): [TBD]
Project Title (שם העבודה): [TBD]
Student Name (שם התלמיד/ה): [TBD]
Student ID (ת.ז. התלמיד/ה): [TBD]
Mentor Name (שם המנחה): [TBD]
Track Name (שם החלופה): תכנות טלפונים חכמים (.NET MAUI) — 883589 (5 יח"ל)
Submission Date (תאריך הגשה): [TBD]
```

## 2. דרישות סף חובה (סעיפים 1–4 — חובה לכל פרויקט)

| סעיף | דרישת החובה במחוון | סטטוס (`PLANNED` / `IMPLEMENTED`) | קובצי מימוש והסבר קצר בהקשר הפרויקט |
| :--- | :--- | :--- | :--- |
| `REQ-1` | אפליקציה לטלפונים חכמים (אנדרואיד) עובדת ללא קריסות | `PLANNED` | `MauiProgram.cs`, `AppShell.xaml` |
| `REQ-2` | לוגיקה מורכבת ומשמעותית מעבר לדרישות המינימום | `PLANNED` | `[ציינו את מחלקות הלוגיקה והאלגוריתמים]` |
| `REQ-3` | ממשק גרפי אינטראקטיבי מרובה מסכים, הנדסת אנוש ונוחות שימוש | `PLANNED` | `Views/*.xaml` |
| `REQ-4` | שימוש באירועים (פקדים, מאזינים, אירועי מערכת) והרשאות זמן-ריצה | `PLANNED` | `ViewModels/*.cs`, `Platforms/Android/AndroidManifest.xml` |

## 3. סעיף 5 — בינה מלאכותית (חובה לממש לפחות נתיב AI אחד מתוך ה-4; נספר גם כנושא 1 בסעיף 6)

*הנחיה: סמנו `PLANNED` (ולאחר מכן `IMPLEMENTED`) בנתיב **אחד או יותר** מתוך הארבעה (חובה לפחות נתיב אחד; מימוש נתיב AI מזכה גם בנושא 1 בסעיף 6, ואין מניעה לשלב יותר מנתיב אחד להעשרת הפרויקט).*

| מזהה | נתיב ה-AI במחוון | סטטוס (`NOT_SELECTED` / `PLANNED` / `IMPLEMENTED`) | מחלקת ה-Service, סכמת הנתונים והשילוב בלוגיקת האפליקציה |
| :--- | :--- | :--- | :--- |
| `AI-1` | נתיב 1: אינטגרציית מודל שפה (`LLM API`) עם סכמת פלט מובנית (`JSON Schema`) ופענוח לאובייקטים/DB | `PLANNED` | `[למשל: Services/AiAnalysisService.cs]` |
| `AI-2` | נתיב 2: שילוב מודלים מוכנים מראש (`Pre-Trained Models` — OCR / זיהוי תמונה או קול) המשולבים בלוגיקה | `NOT_SELECTED` | `-` |
| `AI-3` | נתיב 3: סוכן בינה מלאכותית בזמן ריצה (`Runtime AI Agent`) המזמן פונקציות/לוגיקה פנימית במערכת | `NOT_SELECTED` | `-` |
| `AI-4` | נתיב 4: אימון מודל מותאם אישית (`Custom ML Pipeline` מ-Dataset ועד Inference באפליקציה) | `NOT_SELECTED` | `-` |

## 4. סעיף 6 — נושאי ליבה ו-MAUI (חובה לפחות 2 נושאים; נתיב ה-AI מסעיף 5 נספר כנושא 1)

| מזהה | נושא בסעיף 6 (מותאם ל-.NET MAUI) | סטטוס (`NOT_SELECTED` / `PLANNED` / `IMPLEMENTED`) | קובצי מימוש והסבר |
| :--- | :--- | :--- | :--- |
| `6.1` | תזמון משימות רקע (`Job Scheduler / Work Manager / Background Service`) | `NOT_SELECTED` | `-` |
| `6.3` | הורדת נתוני מידע מהרשת (`REST API` / `HttpClient`) ושימוש בהם בלוגיקה | `PLANNED` | `[למשל: Services/ApiService.cs]` |
| `6.4` | כתיבת מחלקת `Service` משמעותית עם הקשר ישיר לאפליקציה | `PLANNED` | `Services/*.cs` |
| `6.5` | מסד נתונים עם יחסים מורכבים (`1:N` / `M:N`) ושאילתות מתקדמות | `PLANNED` | `Services/*DatabaseService.cs` |
| `6.7` | תצוגת דפים מרובים בהחלקה (`CarouselView` / `TabbedPage` בשילוב `ContentView`) | `NOT_SELECTED` | `-` |
| `6.8` | שימוש ב-`Task` / `async-await` ו-`MainThread` בסביבת MAUI | `PLANNED` | `ViewModels/*.cs`, `Services/*.cs` |
| `6.9` | הקפצת והאזנה לאירועים מאובייקט (`event` / `Invoke` / `WeakReferenceMessenger`) | `PLANNED` | `ViewModels/*.cs` |
| `6.10` | שימוש ב-`DataBinding`, `IValueConverter`, ו-Compiled Bindings (`x:DataType`) | `PLANNED` | `Views/*.xaml`, `Converters/*.cs` |
| `6.11` | שימוש ב-`ObservableCollection<T>` + `CollectionView` | `PLANNED` | `ViewModels/*.cs`, `Views/*.xaml` |
| `6.12` | שימוש ב-`MVVM` מקיף בכל הפרויקט לפי כללי התכנות | `PLANNED` | `Models/`, `Views/`, `ViewModels/`, `Services/` |

## 5. סעיף 7 — אחסון וטיפול בבסיס נתונים (חובה כתיבה וקריאה)

*הנחיה: סמנו לפחות מסד נתונים אחד (`DB-Local` או `DB-Remote-Sync`). שימו לב: מימוש `DB-Remote-Sync` מזכה אוטומטית גם ב-2 נושאים מסעיף 10!*

| מזהה | סוג בסיס הנתונים | סטטוס (`NOT_SELECTED` / `PLANNED` / `IMPLEMENTED`) | טבלאות/אוספים ומחלקת ה-Service |
| :--- | :--- | :--- | :--- |
| `DB-Local` | בסיס נתונים מקומי `SQLite` (`sqlite-net-pcl` + `SQLiteAsyncConnection`) לקריאה וכתיבה | `PLANNED` | `Services/DatabaseService.cs` |
| `DB-Remote-Sync` | בסיס נתונים מרוחק (`Firebase Firestore` / `Realtime DB` / `MySQL`) לקריאה וכתיבה כולל עדכון סינכרוני (מזכה ב-2 נושאים מסעיף 10) | `NOT_SELECTED` | `-` |

## 6. סעיף 8 — נושאים מתקדמים (סעיפים 9 ו-10)

*כלל הזכאות בסעיף 8:*
- **אפשרות 1:** לפחות **3 נושאים מסעיף 9**.
- **אפשרות 2:** לפחות **2 נושאים מסעיף 9** + לפחות **2 נושאים מסעיף 10** *(כולל זיכוי אוטומטי של 2 נושאים מסעיף 10 אם מומש `DB-Remote-Sync`)*.

### טבלת סעיף 9 (חובה לפחות 2 באפשרות 2, או לפחות 3 באפשרות 1):

| מזהה | נושא בסעיף 9 (מותאם ל-.NET MAUI) | סטטוס (`NOT_SELECTED` / `PLANNED` / `IMPLEMENTED`) | קובצי מימוש והסבר |
| :--- | :--- | :--- | :--- |
| `9.1` | מימוש גרפי דו-ממדי ייעודי (`GraphicsView` / קנבס ציור) | `NOT_SELECTED` | `-` |
| `9.2` | התראות מתוזמנות (`AlarmManager / Local Notification`) | `NOT_SELECTED` | `-` |
| `9.3` | ירושה ומימוש `IDrawable` / `GraphicsView` לצורך מימוש גרפי מותאם | `PLANNED` | `Drawables/*.cs` |
| `9.4` | שילוב מפות (`Map`) ושימוש בנתוני מיקום | `NOT_SELECTED` | `-` |
| `9.5` | מאזיני מיקום או תנועה רציפים (`Geolocation Foreground Listener` / `Motion Sensors`) | `NOT_SELECTED` | `-` |
| `9.6` | תקשורת `Bluetooth` (`BLE`) | `NOT_SELECTED` | `-` |
| `9.7` | תקשורת `NFC` | `NOT_SELECTED` | `-` |
| `9.8` | תקשורת ישירה בין מחשבים/מכשירים (`Sockets` / `SignalR`) | `NOT_SELECTED` | `-` |
| `9.9` | פיתוח `API` בצד שרת (בכל שפת תכנות) המשרת את האפליקציה | `NOT_SELECTED` | `-` |
| `9.10` | כתיבת מנוע מוח / מודל אלגוריתמי מורכב (ניווט, שיבוץ, משחק מול המחשב ללא מהלכים אקראיים) | `PLANNED` | `Services/*Engine.cs` |
| `9.11` | טכנולוגיה חדשה (עיבוד תמונה, זיהוי קול מתקדם וכד') | `NOT_SELECTED` | `-` |
| `9.12` | אפליקציית רב-משתתפים סימולטנית בזמן אמת (סנכרון מצב וניהול קונפליקטים בין מכשירים) | `NOT_SELECTED` | `-` |

### טבלת סעיף 10 (נדרשים לפחות 2 נושאים אם נבחרה אפשרות 2 בסעיף 8):

| מזהה | נושא בסעיף 10 (מותאם ל-.NET MAUI) | סטטוס (`NOT_SELECTED` / `PLANNED` / `IMPLEMENTED`) | קובצי מימוש והסבר |
| :--- | :--- | :--- | :--- |
| `10.1` | העברת הודעות מנותקת צימוד / מאזיני מערכת (`WeakReferenceMessenger` / `ConnectivityChanged`) | `NOT_SELECTED` | `-` |
| `10.2` | שמירת העדפות משתמש (`Preferences.Default` / `SharedPreferences`) | `PLANNED` | `Services/PreferencesService.cs` |
| `10.3` | שימוש במצלמה וגלריה (`MediaPicker.Default`) | `PLANNED` | `ViewModels/*.cs` |
| `10.5` | הקלטת שמע ממיקרופון (`Microphone`) | `NOT_SELECTED` | `-` |
| `10.6` | שימוש ב-`GPS` (`Geolocation.Default.GetLocationAsync`) | `NOT_SELECTED` | `-` |
| `10.7` | החזרת תוצאה ממסך משנה (`Shell IQueryAttributable` / Modal Callback) | `NOT_SELECTED` | `-` |
| `10.8` | טיימר ספירה לאחור (`IDispatcherTimer` / `CountDownTimer`) | `NOT_SELECTED` | `-` |
| `10.9` | הקראת טקסט לדיבור (`TextToSpeech.Default.SpeakAsync`) | `NOT_SELECTED` | `-` |
| `10.10` | המרת דיבור לטקסט (`SpeechToText` — `CommunityToolkit.Maui.Media`) | `NOT_SELECTED` | `-` |
| `10.11` | שימוש בחיישני מכשיר (`Sensors` — `Accelerometer` / `Gyroscope` / `Compass`) | `NOT_SELECTED` | `-` |
| `10.12` | לוח שנה עם לוגיקת סינון מתקדמת (`Calendar with filter logic`) | `NOT_SELECTED` | `-` |

## 7. בקרת פרקי תיק הפרויקט (8 פרקי החובה — משקל 20% מהציון)

| פרק | שם הפרק בתיק הפרויקט | סטטוס (`PLANNED` / `IMPLEMENTED`) | מיקום התיעוד בפרויקט |
| :--- | :--- | :--- | :--- |
| `DOC-1` | דף שער (8 שדות חובה) + תוכן עניינים אוטומטי + טבלת תכולות הפרויקט | `PLANNED` | `Learning/Bagrut-Compliance.md`, `Learning/MAUI-Learning-Book.md` |
| `DOC-2` | מבוא (רקע, מחקר מקדים, אתגרים, חידושים) + תיאור תחום הידע | `PLANNED` | `Learning/MAUI-Learning-Book.md` |
| `DOC-3` | מבנה / ארכיטקטורה (ללא קוד: מסך פתיחה, מסכים ופקדים, תרשים זרימת מסכים, תרשים UML) | `PLANNED` | `Learning/Diagrams/`, `Learning/Guides/` |
| `DOC-4` | מימוש הפרויקט (לוגי, גרפי, ניהול; פירוט מחלקות, תכונות, פעולות, תרשימי זרימה ו-DB) | `PLANNED` | `Learning/MAUI-Learning-Book.md`, `Learning/Guides/` |
| `DOC-5` | מדריך למשתמש (התקנה, אמולטורים, אופן הפעלה, הודעות Alert ואילוצים) | `PLANNED` | `Learning/MAUI-Learning-Book.md` |
| `DOC-6` | סיכום אישי / רפלקציה (חצי עמוד עד עמוד לפי 7 נקודות המחוון) | `PLANNED` | `Learning/MAUI-Learning-Book.md` |
| `DOC-7` | ביבליוגרפיה בפורמט APA + טבלת שקיפות קוד AI ומקורות חיצוניים | `PLANNED` | `Learning/AI-And-External-Code-Attribution.md` |
| `DOC-8` | נספחים (תדפיס טקסט מסודר של קוד המחלקות עם הערות תיעוד, ללא צילומי מסך של קוד) | `PLANNED` | `Learning/MAUI-Learning-Book.pdf` |
