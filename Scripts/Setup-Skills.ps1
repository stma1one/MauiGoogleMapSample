param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [switch]$Upgrade,
    [Alias("NoDevFlow")]
    [switch]$SkipDevFlow,
    [Alias("NoCli", "SkipDevFlowCli")]
    [switch]$SkipCli
)

$ErrorActionPreference = "Stop"

$skills = @("maui-k12-baton-workflow", "maui-step-guide-author")
foreach ($skill in $skills) {
    New-Item -ItemType Directory -Path (Join-Path $Root ".agents\skills\$skill") -Force | Out-Null
}

$learningDirectories = @("Learning", "Learning\Guides", "Learning\Mockups", "Learning\Images", "Learning\Diagrams")
foreach ($directory in $learningDirectories) {
    New-Item -ItemType Directory -Path (Join-Path $Root $directory) -Force | Out-Null
}
New-Item -ItemType Directory -Path (Join-Path $Root ".agents") -Force | Out-Null

function Write-FileIfMissing([string]$Path, [string]$Content) {
    if (-not (Test-Path $Path)) {
        $parent = Split-Path -Parent $Path
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    }
}

Write-FileIfMissing (Join-Path $Root ".agents\MAUI-Agent-Mode.json") @'
{
  "studentCapabilityMode": true,
  "includeTests": true,
  "testManagementMode": "combined",
  "description": {
    "true": "MAXIMIZE STUDENT CAPABILITY: staged planning, concept gates, ownership negotiation, student practice, and verification.",
    "false": "MAXIMIZE CODE GENERATED: implement complete feature slices efficiently while preserving verification and learning documentation when configured.",
    "includeTests": "Boolean (default: true). Whether the project provisions, writes, and validates xUnit tests (<AppName>.Tests). When false, testManagementMode is ignored and tests are skipped.",
    "testManagementMode": {
      "combined": "(Default) Combined: Agent creates and explains tests at the end of each stage/slice, proposes selected test cases for the student to write, and documents all tests in Learning/Test-Documentation.md.",
      "agent": "Agent: Agent independently writes and runs xUnit tests as part of the slice workflow and documents them in Learning/Test-Documentation.md.",
      "student": "Student: Agent guides the student through a Socratic dialogue to identify required test cases and coaches the student in writing the xUnit tests.",
      "maximizeCodeOverride": "When studentCapabilityMode is false (MAXIMIZE CODE GENERATED) and includeTests is true, the agent ALWAYS writes and runs all tests regardless of testManagementMode and documents them in Learning/Test-Documentation.md."
    }
  }
}
'@

Write-FileIfMissing (Join-Path $Root "Learning\Current-Phase.md") @'
# Current Phase

```text
Feature:
Phase number:
Phase title:
Primary concept:
Concepts needed now:
Workflow stage:
Baton owner:
Student decisions so far:
Open planning questions:
Approved plan:
Concept gate:
Theory evidence:
Applied coding evidence:
Routine eligibility for agent-owned work:
Ownership split:
Practice offer:
Test plan and coverage:
Agent-owned changes:
Student-owned tasks:
Verification:
Completion criteria:
Status: PLANNING_WITH_STUDENT
```
'@

Write-FileIfMissing (Join-Path $Root "Learning\Student-Mastery.md") @'
# Student Mastery Tracker

This tracker controls learning ownership. Keep theory and coding evidence separate so an explanation is not mistaken for independent implementation ability.

Allowed `Level` values:
- `Not introduced`
- `Practicing`
- `Understands`
- `Can work independently`

Rules:
- `Theory evidence`: the student explains purpose, data flow, choices, or predicted behavior in their own words.
- `Applied coding evidence`: the student independently authors or materially modifies a meaningful code block, then explains and verifies it in `CODE_LEARNING_REVIEWER`. Agent-generated code, copied code, approval, or explaining agent-written code never count.
- `Evidence source`: must name the actual student-authored file/method or checkpoint in this project. If `Evidence source` is `None` or unverifiable, `Routine eligibility` must be `No`.
- Only mark `Level: Can work independently` and `Routine eligibility: Yes` after both evidence tracks are recorded for the same concept.

## Concept Records

### Models
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Define domain model properties and types.

### Properties
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Implement backing fields and explicit getters/setters.

### INotifyPropertyChanged
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Implement explicit property setter with equality check and `OnPropertyChanged([CallerMemberName])`.

### ObservableCollection
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Bind and mutate an `ObservableCollection<T>` in a ViewModel.

### XAML binding
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Use `x:DataType` compiled bindings and typed `DataTemplate`s.

### Commands
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Wire `ICommand` / `Command` in a ViewModel and bind it in XAML.

### CanExecute
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Add a `CanExecute` predicate and trigger `ChangeCanExecute()` when dependent state changes.

### async/await
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Write async methods with `IsLoading`, `try/catch/finally`, and no `.Result` or `.Wait()`.

### DI
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Inject services via constructor and register Services, ViewModels, and Pages in `MauiProgram.cs`.

### Shell navigation
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Register routes in `AppShell` and navigate with `Shell.Current.GoToAsync`.

### validation
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Validate user input in the ViewModel and surface visual error feedback.

### testing
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Propose edge cases and write Arrange-Act-Assert xUnit tests for ViewModel/Service logic.
'@

Write-FileIfMissing (Join-Path $Root "Learning\MAUI-Learning-Book.md") @'
# MAUI Learning Book

This is the student's append-only learning book.

Each meaningful code change should add a compact lesson that explains:
- what changed
- why it changed
- what MAUI/C# concept was learned
- reference docs online to read more and learn
- how to verify the work
- one or two check questions

Always write explanations and lessons in this learning book in **Hebrew** while keeping C#, XAML, and .NET code identifiers in **English**.
'@


Write-FileIfMissing (Join-Path $Root "Learning\Bagrut-Compliance.md") @'
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
'@

Write-FileIfMissing (Join-Path $Root "Learning\AI-And-External-Code-Attribution.md") @'
# יומן שקיפות קוד AI, מקורות חיצוניים וביבליוגרפיה (APA)

מסמך זה מרכז באופן שקוף ומודגש את כל קטעי הקוד בפרויקט שנוצרו בסיוע כלי בינה מלאכותית (AI) או נלקחו ממקורות חיצוניים (GitHub, StackOverflow, תיעוד Microsoft Learn), בהתאם להנחיות משרד החינוך לכתיבת תיק פרויקט (883589).

> **כלל ברזל בפרויקט זה:**
> אין להכניס הערות ייחוס ל-AI (כגון `// Generated by AI`) או מספרי מקורות ביבליוגרפיים לתוך קובצי הקוד (`.cs` / `.xaml`). קובצי הקוד מכילים אך ורק הערות תיעוד מקצועיות (XML Documentation / הסבר לוגי), וכל הייחוס, ההשוואה וההסבר לבוחן מנוהלים במסמך נפרד זה ומשולבים בתיק הפרויקט.

---

## 1. טבלת ייחוס קוד AI ומקורות חיצוניים (הכנה לפרק המימוש ולבחינה בעל-פה — 25% "שליטה בקוד")

בכל סלייס שבו הסוכן מייצר שלד (Scaffold) או קוד שגרתי, או כאשר משולב קוד ממקור חיצוני, יש להוסיף שורה לטבלה זו:

| # | קובץ ומחלקה (`File & Class`) | פעולה / רכיב (`Method / Component`) | מקור (`Agent Scaffold` / `AI Tool` / `External URL`) | מה סופק ע"י ה-AI / המקור החיצוני? | מה התלמיד כתב, שינה או התאים לפרויקט? | נקודות מפתח להסבר בבחינה בעל-פה |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `MauiProgram.cs` | `CreateMauiApp` | `Agent Scaffold` | תבנית בסיסית לרישום פונטים ושירותים ב-DI | התלמיד הוסיף וחיבר את רישום ה-ViewModels, ה-Pages וה-Services של האפליקציה | הסבר ההבדל בין `AddSingleton` ל-`AddTransient` ומדוע `DatabaseService` נרשם כ-Singleton |

---

## 2. רשימת ביבליוגרפיה בפורמט APA (עבור פרק הביבליוגרפיה בתיק הפרויקט)

*הנחיות משרד החינוך:*
- כל קטע קוד משמעותי שיובא מאתר אינטרנט (כגון GitHub, StackOverflow) או מכלי בינה מלאכותית חייב להופיע כאן לפי כללי ה-APA עם קישור ציבורי פעיל (או תיאור הפרומפט והשיחה).
- התייעצות לימודית עם מנוע בינה מלאכותית לצורך הבנת שגיאה או מושג (ללא ייבוא קוד מוכן) אינה דורשת רישום בביבליוגרפיה.

### מקורות מתועדים (APA):

1. Microsoft. (2026). *.NET Multi-platform App UI (.NET MAUI) documentation*. Microsoft Learn. https://learn.microsoft.com/en-us/dotnet/maui/
2. Krueger, F. (2025). *sqlite-net-pcl: Simple, powerful, cross-platform SQLite client and ORM for .NET*. GitHub. https://github.com/praeclarum/sqlite-net
3. Microsoft. (2026). *.NET MAUI DevFlow developer tools*. Microsoft Learn. https://learn.microsoft.com/en-us/dotnet/maui/developer-tools/devflow/?view=net-maui-10.0
4. Versluis, G. [.NET]. (2026, November 13). *Beyond Code Generation: Give AI Eyes and Hands for .NET MAUI* [Video]. YouTube. http://www.youtube.com/watch?v=-3ClD7BHbLU
5. Google. (2026). *Google GenAI .NET SDK (`Google.GenAI`) documentation*. Google APIs. https://googleapis.github.io/dotnet-genai/
6. Microsoft. (2026). *.NET MAUI Map control (`Microsoft.Maui.Controls.Maps`) documentation*. Microsoft Learn. https://learn.microsoft.com/en-us/dotnet/maui/user-interface/controls/map?view=net-maui-10.0
7. Google. (2026). *שימוש במפתחות API עם Maps SDK ל-Android (Get an API Key)*. Google Developers. https://developers.google.com/maps/documentation/android-sdk/get-api-key?hl=he
'@

function Sync-SkillIfPresent([string]$Source, [string]$Destination) {
    if (Test-Path $Source) {
        if (Test-Path $Destination) {
            Remove-Item -LiteralPath $Destination -Recurse -Force
        }
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        Get-ChildItem -Path $Source | ForEach-Object {
            if ($_.Name -eq "evals") { return }
            Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
        }
    }
}

$packageRoot = Join-Path $Root "SkillPackages\maui-k12-baton-workflow"
if (Test-Path $packageRoot) {
    Sync-SkillIfPresent (Join-Path $packageRoot "skills\maui-k12-baton-workflow") (Join-Path $Root ".agents\skills\maui-k12-baton-workflow")
    Sync-SkillIfPresent (Join-Path $packageRoot "companion-skills\maui-step-guide-author\skills\maui-step-guide-author") (Join-Path $Root ".agents\skills\maui-step-guide-author")
}

$targetScriptsDir = Join-Path $Root "Scripts"
New-Item -ItemType Directory -Path $targetScriptsDir -Force | Out-Null
$skillScriptsDir = Join-Path $Root ".agents\skills\maui-step-guide-author\scripts"
$toolMap = @{
    "generate_book_pdf.py" = "Generate-Learning-Book-Pdf.py"
    "capture_mockup_blocks.py" = "Capture-Mockup-Blocks.py"
    "validate_learning_book.py" = "Validate-Learning-Book.py"
    "validate_bagrut_compliance.py" = "Validate-Bagrut-Compliance.py"
    "generate_architecture_diagrams.py" = "Generate-Architecture-Diagrams.py"
    "ensure_maui_devflow.py" = "Ensure-Maui-DevFlow.py"
    "ensure_test_project.py" = "Ensure-Test-Project.py"
    "validate_tests.py" = "Validate-Tests.py"
    "requirements-learning-book.txt" = "Learning-Book-Requirements.txt"
}

foreach ($entry in $toolMap.GetEnumerator()) {
    $source = Join-Path $skillScriptsDir $entry.Key
    if (Test-Path $source) {
        Copy-Item -LiteralPath $source -Destination (Join-Path $targetScriptsDir $entry.Value) -Force
    }
}

$ensureTests = Join-Path $targetScriptsDir "Ensure-Test-Project.ps1"
if (Test-Path $ensureTests) {
    & $ensureTests -ProjectRoot $Root
}

$learningBookSetup = Join-Path $targetScriptsDir "Setup-Learning-Book.ps1"
if (Test-Path $learningBookSetup) {
    & $learningBookSetup -ProjectRoot $Root
}

Write-Host "MAUI K12 skill structure, visual-capture tools, and learning-book validation are ready." -ForegroundColor Green
Write-Host "Default mode: MAXIMIZE STUDENT CAPABILITY" -ForegroundColor Cyan

$ensureDevFlow = Join-Path $targetScriptsDir "Ensure-Maui-DevFlow.ps1"
if ($SkipDevFlow) {
    Write-Host "[SKIP] MAUI DevFlow automatic injection skipped (-SkipDevFlow)." -ForegroundColor Yellow
}
elseif (Test-Path $ensureDevFlow) {
    $devFlowArgs = @{ ProjectRoot = $Root }
    if ($Upgrade) {
        $devFlowArgs.Upgrade = $true
    }
    if ($SkipCli) {
        $devFlowArgs.SkipCli = $true
    }
    & $ensureDevFlow @devFlowArgs
}