# ☕ CoffeeMap — .NET 10 MAUI Google Maps Sample Project

פרויקט דוגמה ולמידה מודרך ב-**.NET 10 MAUI** לבניית אפליקציית **CoffeeMap** (איתור תחנות קפה, תצוגת מפות Google, סיכות אינטראקטיביות, מיקום GPS בזמן אמת ומסלולי קפה על גבי המפה) — כתוב ב-**Vanilla C# MVVM** (ללא Source Generators), עם **Dependency Injection** בגישת Fluent Builder, בדיקות יחידה ב-**`xunit.v3`**, ומדריכי PDF מלאים בעברית לכל שלב.

---

## 🎯 מה כולל הפרויקט?

- **אפליקציית `.NET 10 MAUI`** (`MauiGoogleMapSample/`) עם 5 מסכים המחוברים דרך `AppShell` (תפריט `Flyout` צדדי בעברית עם אייקונים וקטוריים).
- **ארכיטקטורת Vanilla C# MVVM נקייה**: מימוש מפורש של `INotifyPropertyChanged`, `ICommand` ו-`CanExecute`, הפרדה מלאה בין `Views`, `ViewModels`, `Services` ו-`Models`.
- **הזרקת תלויות (DI) בגישת Fluent Builder** ב-`MauiProgram.cs`: `RegisterServices()`, `RegisterViewModels()`, `RegisterViews()`.
- **אבטחת מפתח Google Maps API**: שימוש ב-`Secrets.props` + `.gitignore` + `AndroidManifestPlaceholders` כך שהמפתח לעולם אינו נדחף ל-Git.
- **פרויקט בדיקות יחידה (`MauiGoogleMapSample.Tests/`)**: 31 בדיקות יחידה ב-`xunit.v3` לפי תבנית **AAA** (Arrange / Act / Assert), כולל `FakeLocationService` לבדיקת לוגיקת GPS ללא תלות בחומרה.
- **מדריכי PDF מלאים בעברית ומשימות לתלמידים (`MauiGoogleMapSample/Docs/`)**:
  - מדריך עבודה עם בדיקות יחידה (`00-Working-With-Unit-Tests.pdf`)
  - מדריך אבטחת מפתח API עם `Secrets.props` ו-`.gitignore` (`01b-Securing-Api-Key-With-Secrets-And-GitIgnore.pdf`)
  - 5 מדריכי פיתוח מדורגים (`01` עד `05`) כולל צילומי מסך אמיתיים מהאמולטור, הסברי תחביר C# למתחילים והסבר מלא על ממשקים ומימושם
  - 5 דפי משימות לתרגול (`Docs/Assignments/01` עד `05`)
  - 3 תרשימי ארכיטקטורה לרוחב (`Architecture-Overview.pdf`, `Architecture-UML.pdf`, `Screen-Flow.pdf`)

---

## 🌿 מבנה הענפים (Git Branches)

הפרויקט בנוי בצורה מדורגת כך שכל ענף מכיל את הקוד ואת מסמכי ה-PDF שבוצעו עד לאותו שלב (כולל השלב עצמו), ואילו הענף הראשי `main` מכיל את **כל** מדריכי ה-PDF, המשימות ותרשימי הארכיטקטורה המלאים:

| ענף (Branch) | שלב | תוכן מרכזי | מסמכים ב-`MauiGoogleMapSample/Docs/` |
|---|---|---|---|
| `main` | בסיס + תיעוד מלא | שלד הפרויקט + **כל 15 קבצי ה-PDF** (מדריכים, משימות ותרשימי ארכיטקטורה) | כל 15 קבצי ה-PDF |
| `stage/01-setup-and-permissions` | שלב 1 | התקנת `Microsoft.Maui.Controls.Maps`, הגדרת `AndroidManifest.xml`, אבטחת מפתח ב-`Secrets.props`, Fluent DI ו-`MainPage` | `00`, `01`, `01b`, `Assignments/01` |
| `stage/02-map-display-and-types` | שלב 2 | `MapDisplayPage`: הצגת `<maps:Map>`, מעבר בין `Street` / `Satellite` / `Hybrid`, זום ובחירת עיר (`MapSpan`) | עד שלב 2 + `Assignments/01–02` |
| `stage/03-pins-and-callouts` | שלב 3 | `CoffeePinsPage`: קישור `ItemsSource` ל-`<maps:Pin>`, חיפוש וסינון חי, ואירועי `MarkerClicked` / `InfoWindowClicked` | עד שלב 3 + `Assignments/01–03` |
| `stage/04-gps-and-user-location` | שלב 4 | `UserLocationPage`: הרשאות GPS בזמן ריצה (`Permissions.LocationWhenInUse`), `Geolocation`, `IsShowingUser` ואיתור התחנה הקרובה | עד שלב 4 + `Assignments/01–04` |
| `stage/05-shapes-and-routes` | שלב 5 (מלא) | `CoffeeRoutesPage`: שכבות `MapElements` (`Polyline` למסלול קפה + `Circle` לאזור משלוחים), תפריט `Flyout` מלא וכל 31 הבדיקות | **כל 15 קבצי ה-PDF** |

---

## 🚀 התחלה מהירה (Setup)

### 1. שכפול הפרויקט ומעבר לענף הרצוי
```bash
git clone https://github.com/stma1one/MauiGoogleMapSample.git
cd MauiGoogleMapSample

# להצגת הפתרון המלא של כל 5 השלבים:
git checkout stage/05-shapes-and-routes
```

### 2. הגדרת מפתח Google Maps API (מקומית בלבד)
1. העתיקו את הקובץ `MauiGoogleMapSample/Secrets.props.example` לקובץ חדש בשם:
   `MauiGoogleMapSample/Secrets.props`
2. הדביקו את מפתח ה-Google Maps API שלכם במקום ה-Placeholder.
3. הקובץ `Secrets.props` מוחרג אוטומטית ב-`.gitignore` ולכן לא יידחף ל-GitHub.

### 3. בנייה והרצת בדיקות יחידה
```bash
dotnet build MauiGoogleMapSample.slnx
dotnet test MauiGoogleMapSample.Tests/MauiGoogleMapSample.Tests.csproj
```

---

## 📁 מבנה תיקיות עיקרי

```text
MauiGoogleMapSample/
├── MauiGoogleMapSample/                 # אפליקציית .NET 10 MAUI
│   ├── Models/                          # CoffeeRegion, CoffeeStation
│   ├── Services/                        # ממשקים ושירותים (Validator, Regions, Stations, Location, Routes)
│   ├── ViewModels/                      # BaseViewModel ו-5 ViewModels (Vanilla MVVM)
│   ├── Views/                           # 5 מסכי XAML + AppShell (Flyout)
│   ├── Platforms/Android/               # AndroidManifest.xml עם ${GoogleMapsApiKey}
│   ├── Docs/                            # כל מדריכי ה-PDF, המשימות ותרשימי הארכיטקטורה
│   └── Secrets.props.example            # תבנית להזרקת מפתח API מקומי
├── MauiGoogleMapSample.Tests/           # 31 בדיקות יחידה ב-xunit.v3
└── README.md
```

---

*נוצר על ידי טל סימון - tal.simon@gmail.com*
