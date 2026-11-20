# שלב 3: סיכות על המפה (`Pins`), קישור נתונים ואירועי לחיצה

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git (Branch):** `stage/03-pins-and-callouts`  
> **קהל יעד:** תלמידים מתחילים בפיתוח אפליקציות מובייל (.NET MAUI)

---

## 1. מה זה `Pin` במפה ומה המבנה שלו?

כשאנחנו פותחים Google Maps או Waze ורואים "נעץ" או סמן צבעוני על מסעדה או תחנת קפה — ב-.NET MAUI הרכיב הזה נקרא **`Pin`** (סיכה).

לכל `Pin` יש 4 מאפיינים עיקריים שחשוב להכיר לפני השימוש:

| מאפיין (`Property`) | טיפוס | תפקיד על המפה |
| :--- | :--- | :--- |
| `Location` | `Location` | הקואורדינטות (`Latitude`, `Longitude`) שבהן הסיכה תוצב. |
| `Label` | `string` | הכותרת הראשית שתופיע בבועה (Callout / InfoWindow) כשלוחצים על הסיכה (למשל: `"קפה רוטשילד 45"`). |
| `Address` | `string` | שורת המשנה בבועה — הכתובת הפיזית של תחנת הקפה. |
| `Type` | `PinType` | סיווג הסיכה: `Generic`, `Place`, `SavedPin`, או `SearchResult`. |

---

## 2. איך מחברים רשימת תחנות קפה לסיכות ב-MVVM?

מתחילים רבים מתפתים לכתוב לולאת `foreach` בתוך `Code-Behind` כדי להוסיף סיכות ידנית (`Map.Pins.Add(...)`).  
בארכיטקטורת **MVVM** נקייה יש דרך טובה ופשוטה בהרבה: **`ItemsSource` + `ItemTemplate`** — בדיוק כמו ב-`CollectionView`!

```xml
<maps:Map x:Name="PinsMapControl"
          ItemsSource="{Binding Stations}">
    <maps:Map.ItemTemplate>
        <DataTemplate x:DataType="models:CoffeeStation">
            <maps:Pin Location="{Binding Location}"
                      Label="{Binding Name}"
                      Address="{Binding Address}"
                      Type="Place"
                      MarkerClicked="OnPinMarkerClicked"
                      InfoWindowClicked="OnPinInfoWindowClicked" />
        </DataTemplate>
    </maps:Map.ItemTemplate>
</maps:Map>
```

### למה זה כל כך חזק?
מכיוון ש-`Stations` הוא `ObservableCollection<CoffeeStation>` ב-`CoffeePinsViewModel`, **בכל פעם שאנחנו מסננים או מוסיפים תחנת קפה לרשימה — הסיכות על המפה מתעדכנות אוטומטית!**

---

## 3. ההבדל בין `MarkerClicked` ל-`InfoWindowClicked`

במפות Google יש **שני אירועי לחיצה שונים** על כל `Pin`:
1. **`MarkerClicked`** — מופעל כשלוחצים על **הסיכה עצמה** (הנעץ). בדוגמה שלנו, לחיצה כזו מעדכנת את פס המידע בתחתית המסך עם פרטי תחנת הקפה והדירוג שלה.
2. **`InfoWindowClicked`** — מופעל כשלוחצים על **חלונית המידע (הבועה)** שנפתחת מעל הסיכה. בדוגמה שלנו, לחיצה כזו מציגה חלון פרטים מלא באמצעות `await DisplayAlertAsync(...)` (השיטה המודרנית ב-.NET 10 MAUI).

---

## 4. אימות והרצת הבדיקות
ודאו שהפתרון מתקמפל ושכל הבדיקות (כולל `CoffeeStationServiceTests` ו-`CoffeePinsViewModelTests`) עוברות:
* ב-Visual Studio: `Build -> Build Solution`, ואז `Test -> Test Explorer -> Run All Tests`.
* או בטרמינל: `dotnet build` ולאחריו `dotnet test`.

למשימת התרגול שלכם, פתחו את [`Docs/Assignments/03-Pins-And-Callouts-Assignment.pdf`](Assignments/03-Pins-And-Callouts-Assignment.pdf).
