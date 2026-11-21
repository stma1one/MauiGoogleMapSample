# שלב 3: סיכות על המפה (`Pins`), קישור נתונים ואירועי לחיצה

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git (Branch):** `stage/03-pins-and-callouts`  
> **קהל יעד:** תלמידים מתחילים בפיתוח אפליקציות מובייל (.NET MAUI)  
> **מקרא צבעים בקוד:** שורות המודגשות ב**רקע ירוק וטקסט צהוב** הן שורות חדשות שיש להוסיף לתוך קובץ קיים.

---

## 1. מה אנחנו בונים בשלב הזה? (תצוגת המסך)

בשלב זה נבנה צעד אחר צעד את מסך **`CoffeePinsPage`** שמציג 4 תחנות קפה על המפה כסיכות (`Pins`), מאפשר לסנן אותן בזמן אמת משורת חיפוש, ומגיב ללחיצה על הסיכה (`MarkerClicked`) או על בועת המידע שלה (`InfoWindowClicked`):

![תצוגת מסך שלב 3 (צילום חי מאימולטור Android) - CoffeePinsPage](../../Learning/Images/CoffeePinsPage-live.png)

> **שימו לב:** כמו בשלב 2, אריחי המפה והסיכות הגרפיות יוצגו במלואם ברגע שתגדירו מפתח Google Maps API אמיתי בקובץ המקומי `Secrets.props` (ראו מדריך `01b`).

---

## 2. מה מובנה ב-.NET MAUI לעומת מה אנחנו יוצרים בעצמנו?

| רכיב | מאיפה הוא מגיע? | תפקיד |
| :--- | :--- | :--- |
| `<maps:Pin>` (`Location`, `Label`, `Address`, `Type`) | **מובנה ב-`Microsoft.Maui.Controls.Maps`** | סמן ("נעץ") המוצג על המפה ובועת המידע שנפתחת מעליו. |
| `MarkerClicked` ו-`InfoWindowClicked` | **Events מובנים של `<maps:Pin>`** | מופעלים אוטומטית כשהמשתמש לוחץ על הסיכה עצמה או על הבועה שמעליה. |
| `DisplayAlertAsync(...)` | **מתודה מובנית ב-`ContentPage` (.NET 10 MAUI)** | מציגה חלון התראה אסינכרוני למשתמש (מחליפה את `DisplayAlert` המיושן). |
| `Dispatcher.Dispatch(...)` | **מובנה ב-`ContentPage` (.NET MAUI)** | מתזמן את מיקוד המפה בבטחה על ה-UI Thread. |
| `CoffeeStation` (`Models/CoffeeStation.cs`) | **מחלקה שיצרנו בעצמנו** | מודל נתונים לתחנת קפה אחת. |
| `ICoffeeStationService` / `CoffeeStationService` | **מחלקה שיצרנו בעצמנו (`Services/`)** | מאגר תחנות הקפה ומתודת הסינון לפי חיפוש. |
| `CoffeePinsViewModel` (`ViewModels/CoffeePinsViewModel.cs`) | **מחלקה שיצרנו בעצמנו** | מנהלת את רשימת התחנות, החיפוש, הסינון ופס המידע. |

---

## 3. שלב א' — בניית המודל (`Models`) ושירות התחנות (`Services`)

### 3.1 המודל: `Models/CoffeeStation.cs`
כל מופע של `CoffeeStation` מייצג תחנת קפה אחת שתוצג כסיכה (`Pin`) על המפה:

| מאפיין (`Property`) | טיפוס | הסבר ושימוש |
| :--- | :--- | :--- |
| `Id` | `string` | מזהה ייחודי של תחנת הקפה (למשל `"tlv-1"`). |
| `Name` | `string` | שם תחנת הקפה — יוצג ככותרת הסיכה (`Pin.Label`). |
| `Address` | `string` | הכתובת הפיזית — תוצג כשורת המשנה בבועה (`Pin.Address`). |
| `Specialty` | `string` | התמחות הקפה (למשל `"אספרסו וקולד ברו"`) — משמשת לסינון ולפס המידע. |
| `Rating` | `double` | דירוג כוכבים (למשל `4.8`). |
| `Latitude` / `Longitude` | `double` | קואורדינטות התחנה על המפה. |
| `Location` | `Location` | **מאפיין מחושב** שמחזיר אובייקט `Location` מוכן ל-`Pin.Location`. |

```csharp
using Microsoft.Maui.Devices.Sensors;

namespace MauiGoogleMapSample.Models;

/// <summary>
/// מייצג תחנת קפה בודדת שמוצגת כסיכה (Pin) על המפה.
/// </summary>
public class CoffeeStation
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Specialty { get; set; } = string.Empty;
    public double Rating { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }

    // מאפיין מחושב לקריאה בלבד (ראו הסבר על התחביר => בתיבה מתחת לקוד)
    public Location Location => new Location(Latitude, Longitude);
}
```

<div class="alert-important">
<strong>💡 תחביר C# למתחילים — מה זה <code>=&gt;</code> במאפיין?</strong><br/>
השורה <code>public Location Location =&gt; new Location(Latitude, Longitude);</code> נקראת <strong>Expression-Bodied Property</strong>.<br/>
היא קיצור נקי של:<br/>
<code>public Location Location { get { return new Location(Latitude, Longitude); } }</code>.
</div>

### 3.2 הגדרת הממשק (`Interface`): `Services/ICoffeeStationService.cs`

לפני שכותבים את המחלקה עצמה, מגדירים **ממשק (`interface`)** שקובע את ה"חוזה" של השירות — **אילו פעולות השירות מבטיח לספק**, בלי להתחייב *איך* הן ממומשות (היום מרשימה בזיכרון, ומחר אולי ממסד נתונים או שרת אינטרנט!).

| פעולה בממשק | קלט ופלט | למה הפעולה הוגדרה בחוזה? |
| :--- | :--- | :--- |
| `GetStations()` | ללא קלט → `IReadOnlyList<CoffeeStation>` | מאפשרת ל-ViewModel לטעון את כל תחנות הקפה בעליית המסך (או בעת ניקוי סינון). |
| `FilterStations(string? query)` | מילת חיפוש (אופציונלית) → `IReadOnlyList<CoffeeStation>` | מאפשרת לסנן תחנות לפי שם, כתובת או התמחות בלי שה-ViewModel יצטרך להכיר את לוגיקת החיפוש. |

```csharp
using MauiGoogleMapSample.Models;

namespace MauiGoogleMapSample.Services;

/// <summary>
/// חוזה לשירות שמספק את רשימת תחנות הקפה ומאפשר לסנן אותן לפי מילת חיפוש.
/// (ראו הסבר על הטיפוס IReadOnlyList בתיבה מתחת לקוד)
/// </summary>
public interface ICoffeeStationService
{
    /// <summary>מחזיר את כל תחנות הקפה במאגר לקריאה בלבד.</summary>
    IReadOnlyList<CoffeeStation> GetStations();

    /// <summary>מחזיר רק תחנות ששמן, כתובתן או התמחותן מכילה את מילת החיפוש.</summary>
    IReadOnlyList<CoffeeStation> FilterStations(string? query);
}
```

<div class="alert-important">
<strong>💡 מה זה <code>IReadOnlyList&lt;T&gt;</code> ולמה דווקא בחרנו בו (ולא ב-<code>List&lt;T&gt;</code>)?</strong><br/>
• <code>IReadOnlyList&lt;CoffeeStation&gt;</code> מאפשר למי שמקבל את הרשימה <strong>לקרוא</strong> איברים (<code>foreach</code>, <code>Count</code>, <code>[0]</code>), אך <strong>מונע ממנו לשנות</strong> את הרשימה המקורית (אין עליו <code>Add</code>, <code>Remove</code> או <code>Clear</code>).<br/>
• כך אנו שומרים על עקרון ה<strong>כימוס (Encapsulation)</strong>: ה-ViewModel לא יכול למחוק או להשחית בטעות את המאגר הפנימי <code>_stations</code> של השירות — הוא מקבל רשימה לקריאה בלבד ומעתיק ממנה ל-<code>ObservableCollection</code> הפרטי שלו.
</div>

### 3.3 המחלקה המממשת את הממשק: `Services/CoffeeStationService.cs`

כעת יוצרים קובץ ומחלקה נפרדים ש**מממשים את הממשק** (`public class CoffeeStationService : ICoffeeStationService`).  
המחלקה מחזיקה רשימה פרטית `_stations` של 4 תחנות קפה בתל אביב ומממשת את **שתי הפעולות** שהוגדרו בממשק:

1. **מימוש `GetStations()`** — מחזיר עטיפת קריאה-בלבד (`_stations.AsReadOnly()`) כדי להגן על הרשימה הפנימית משינוי חיצוני.
2. **מימוש `FilterStations(string? query)`** — מנקה רווחים (`query.Trim()`) ומסנן עם LINQ `Where` לפי שם, כתובת או התמחות ללא תלות באותיות גדולות/קטנות (`StringComparison.OrdinalIgnoreCase`).

```csharp
using MauiGoogleMapSample.Models;

namespace MauiGoogleMapSample.Services;

// תחילת המחלקה המממשת את הממשק ICoffeeStationService
public class CoffeeStationService : ICoffeeStationService
{
    private readonly List<CoffeeStation> _stations = new()
    {
        new CoffeeStation { Id = "tlv-1", Name = "קפה רוטשילד 45", Address = "שדרות רוטשילד 45, תל אביב", Specialty = "אספרסו וקולד ברו", Rating = 4.8, Latitude = 32.0636, Longitude = 34.7731 },
        new CoffeeStation { Id = "tlv-2", Name = "קליית שנקין", Address = "רחוב שנקין 22, תל אביב", Specialty = "פילטר וקלייה מקומית", Rating = 4.6, Latitude = 32.0695, Longitude = 34.7720 },
        new CoffeeStation { Id = "tlv-3", Name = "תחנת הקפה נווה צדק", Address = "רחוב שבזי 30, תל אביב", Specialty = "מאצ'ה וקפוצ'ינו שיבולת שועל", Rating = 4.4, Latitude = 32.0604, Longitude = 34.7652 },
        new CoffeeStation { Id = "tlv-4", Name = "בוקר בנמל", Address = "האנגר 12, נמל תל אביב", Specialty = "אספרסו קלאסי ומאפים", Rating = 4.2, Latitude = 32.0965, Longitude = 34.7745 }
    };

    /// <summary>מימוש פעולה 1: מחזיר את כל 4 התחנות לקריאה בלבד.</summary>
    public IReadOnlyList<CoffeeStation> GetStations()
    {
        return _stations.AsReadOnly();
    }

    /// <summary>מימוש פעולה 2: מסנן את התחנות לפי טקסט חיפוש.</summary>
    public IReadOnlyList<CoffeeStation> FilterStations(string? query)
    {
        // אם שורת החיפוש ריקה או מכילה רווחים בלבד — מחזירים את כל התחנות
        if (string.IsNullOrWhiteSpace(query))
        {
            return _stations.AsReadOnly();
        }

        // מסיר רווחים מיותרים מההתחלה ומהסוף (ראו הסבר על Trim() בתיבה מתחת לקוד)
        string trimmed = query.Trim();

        // LINQ Where: משאיר רק תחנות שמתאימות לחיפוש (ראו הסבר על StringComparison בתיבה מתחת לקוד)
        return _stations
            .Where(s =>
                s.Name.Contains(trimmed, StringComparison.OrdinalIgnoreCase) ||
                s.Address.Contains(trimmed, StringComparison.OrdinalIgnoreCase) ||
                s.Specialty.Contains(trimmed, StringComparison.OrdinalIgnoreCase))
            .ToList();
    }
}
```

<div class="alert-important">
<strong>💡 הסבר על <code>query.Trim()</code> ועל <code>StringComparison.OrdinalIgnoreCase</code>:</strong><br/>
• <strong><code>string trimmed = query.Trim();</code></strong> — מנקה רווחים מיותרים מתחילת המחרוזת ומסופה. במכשירים ניידים מקלדות מוסיפות לעיתים רווח אוטומטי בסוף מילה (למשל <code>"אספרסו "</code>); בלי <code>Trim()</code> החיפוש היה נכשל!<br/>
• <strong><code>StringComparison.OrdinalIgnoreCase</code></strong> — אומר ל-C# לבדוק התאמה <strong>ללא תלות באותיות גדולות/קטנות</strong> (כך <code>"espresso"</code> יתאים ל-<code>"Espresso"</code>) ובאופן מהיר שאינו תלוי בשפת המכשיר.
</div>

| אפשרות ב-`StringComparison` | משמעות | מתי משתמשים? |
| :--- | :--- | :--- |
| `OrdinalIgnoreCase` | השוואה מהירה לפי קוד תו, מתעלמת מ-`A`/`a` | **המומלצת ביותר** לחיפוש טקסט, שמות, קודים וכתובות. |
| `Ordinal` | השוואה מהירה ומדויקת שמבדילה בין `A` ל-`a` | בדיקת סיסמאות, טוקנים או מזהי `Id` מדויקים. |
| `CurrentCulture` / `CurrentCultureIgnoreCase` | השוואה לפי כללי השפה והמיון המוגדרים במכשיר המשתמש | מיון רשימות לתצוגה תלוית-שפה. |
| `InvariantCultureIgnoreCase` | השוואה בלתי-תלויה בשפת המכשיר עם כללי תרבות אחידים | נתונים בינלאומיים קבועים (כמו פורמטים טכניים). |

---

## 4. שלב ב' — בניית ה-ViewModel שלב אחר שלב (`ViewModels/CoffeePinsViewModel.cs`)

### צעד 1: הגדרת המחלקה והבנאי (`Constructor`)
ה-ViewModel יורש מ-`BaseViewModel`, מקבל `ICoffeeStationService` ב-DI, טוען את כל תחנות הקפה לתוך `ObservableCollection<CoffeeStation>` ומאתחל את הפקודות:

```csharp
public class CoffeePinsViewModel : BaseViewModel
{
    private readonly ICoffeeStationService _stationService;
    private string _searchQuery = string.Empty;
    private CoffeeStation? _selectedStation;
    private string _selectedStationBanner = "לחצו על סיכה במפה כדי לראות פרטי תחנת קפה";

    public CoffeePinsViewModel(ICoffeeStationService stationService)
    {
        _stationService = stationService;
        Title = "CoffeeMap — שלב 3: סיכות (Pins)";

        Stations = new ObservableCollection<CoffeeStation>(_stationService.GetStations());

        _filterCommand = new Command(ExecuteFilter);
        _clearFilterCommand = new Command(ExecuteClearFilter, CanExecuteClearFilter);
        _selectStationByNameCommand = new Command<string>(ExecuteSelectStationByName);
    }
}
```

### צעד 2: טבלת כל ה-Properties ב-`CoffeePinsViewModel` והשימוש בהם

| מאפיין (`Property`) | טיפוס | תפקיד ושימוש ב-XAML / לוגיקה |
| :--- | :--- | :--- |
| `Title` (מורש מ-`BaseViewModel`) | `string` | כותרת הדף בסרגל העליון. |
| `Stations` | `ObservableCollection<CoffeeStation>` | רשימת התחנות — מחובר ל-`<maps:Map ItemsSource="{Binding Stations}">`. |
| `SearchQuery` | `string` | טקסט החיפוש מה-`Entry` — מפעיל `ClearFilterCommand.ChangeCanExecute()` כשהטקסט משתנה. |
| `SelectedStation` | `CoffeeStation?` | תחנת הקפה האחרונה שנבחרה בלחיצה על סיכה (`?` = יכול להיות `null` בהתחלה). |
| `SelectedStationBanner` | `string` | פס המידע בתחתית המסך (`Label Text="{Binding SelectedStationBanner}"`). |

```csharp
public string SearchQuery
{
    get => _searchQuery;
    set
    {
        if (_searchQuery == value) return;
        _searchQuery = value;
        OnPropertyChanged();
        // מעדכן את כפתור "נקה" — פעיל רק כשיש טקסט בשדה החיפוש!
        _clearFilterCommand.ChangeCanExecute();
    }
}
```

### צעד 3: הפקודות (`FilterCommand`, `ClearFilterCommand`, `SelectStationByNameCommand`)
* **`ExecuteFilter()`**: מנקה את `Stations` ומכניס אליו רק את תוצאות הסינון — ומכיוון ש-`Stations` הוא `ObservableCollection`, **הסיכות על המפה מתעדכנות אוטומטית!**
* **`CanExecuteClearFilter()`**: מחזיר `!string.IsNullOrWhiteSpace(SearchQuery)` (כך כפתור `"נקה"` מושבת אוטומטית כשאין חיפוש).
* **`ExecuteSelectStationByName(string? stationName)`**: מאתר את התחנה לפי השם שנלחץ בסיכה ומעדכן את `SelectedStation`.

```csharp
private void ExecuteFilter()
{
    IReadOnlyList<CoffeeStation> filtered = _stationService.FilterStations(SearchQuery);
    Stations.Clear();
    foreach (CoffeeStation station in filtered)
    {
        Stations.Add(station);
    }

    // אופרטור תנאי מקוצר (? :): אם לא נמצאו תוצאות הצג הודעה מתאימה, אחרת הצג את הכמות
    SelectedStationBanner = filtered.Count == 0
        ? "לא נמצאו תחנות קפה התואמות לחיפוש."
        : $"נמצאו {filtered.Count} תחנות קפה על המפה.";
}
```

### צעד 4: חישוב המיקוד הראשוני (`GetInitialMapSpan`)
```csharp
public MapSpan GetInitialMapSpan()
{
    // FirstOrDefault מחזיר את התחנה הראשונה או null אם הרשימה ריקה
    CoffeeStation? first = Stations.FirstOrDefault();
    Location center = first is not null ? first.Location : new Location(32.0636, 34.7731);
    return MapSpan.FromCenterAndRadius(center, Distance.FromKilometers(3.0));
}
```

---

## 5. שלב ג' — בניית ה-XAML שלב אחר שלב (`Views/CoffeePinsPage.xaml`)

### צעד 1: הגדרת כותרת ה-`ContentPage` ומרחבי השמות (`xmlns`)
```xml
<ContentPage xmlns="http://schemas.microsoft.com/dotnet/2021/maui"
             xmlns:x="http://schemas.microsoft.com/winfx/2009/xaml"
+            xmlns:maps="http://schemas.microsoft.com/dotnet/2021/maui/maps"
+            xmlns:models="clr-namespace:MauiGoogleMapSample.Models"
+            xmlns:vm="clr-namespace:MauiGoogleMapSample.ViewModels"
             x:Class="MauiGoogleMapSample.Views.CoffeePinsPage"
+            x:DataType="vm:CoffeePinsViewModel"
+            FlowDirection="RightToLeft"
             Title="{Binding Title}">
```

### צעד 2: חלוקת המסך ל-3 שורות (`Grid`) ושורת החיפוש (`Row 0`)
```xml
<Grid RowDefinitions="Auto,*,Auto" RowSpacing="8" Padding="12">
    <!-- Row 0: תיבת חיפוש + כפתורי סנן ונקה -->
    <Grid Grid.Row="0" ColumnDefinitions="*,Auto,Auto" ColumnSpacing="6">
        <Entry Grid.Column="0" Placeholder="חפש תחנת קפה (למשל: אספרסו, שנקין)..." Text="{Binding SearchQuery}" />
        <Button Grid.Column="1" Text="סנן" Command="{Binding FilterCommand}" />
        <Button Grid.Column="2" Text="נקה" Command="{Binding ClearFilterCommand}" BackgroundColor="{StaticResource Gray500}" />
    </Grid>
```

### צעד 3: קישור הסיכות (`ItemsSource` + `ItemTemplate`) ב-`Row 1` ופס מידע ב-`Row 2`
במקום לכתוב לולאת `foreach` ידנית ב-C#, קושרים את `ItemsSource` של המפה אל `Stations`, ובתוך `DataTemplate` מגדירים איך כל `CoffeeStation` הופך ל-`<maps:Pin>`:

```xml
    <!-- Row 1: מפה עם סיכות קשורות ל-ObservableCollection -->
    <Border Grid.Row="1" StrokeShape="RoundRectangle 12" Stroke="{StaticResource Gray300}">
        <maps:Map x:Name="PinsMapControl" ItemsSource="{Binding Stations}" IsScrollEnabled="True" IsZoomEnabled="True">
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
    </Border>

    <!-- Row 2: פס המידע על הסיכה הנבחרת -->
    <Border Grid.Row="2" StrokeShape="RoundRectangle 8" Padding="12" BackgroundColor="{StaticResource Gray100}">
        <Label Text="{Binding SelectedStationBanner}" FontSize="13" FontAttributes="Bold" />
    </Border>
</Grid>
```

---

## 6. שלב ד' — בניית ה-Code-Behind שלב אחר שלב (`Views/CoffeePinsPage.xaml.cs`)

### פירוט כל הפעולות ב-`CoffeePinsPage.xaml.cs`:

| פעולה (`Method`) | מתי היא מופעלת? | מה היא עושה ולמה היא חשובה? |
| :--- | :--- | :--- |
| `CoffeePinsPage(CoffeePinsViewModel viewModel)` | בעת יצירת הדף (DI) | טוענת את ה-XAML ומחברת את ה-ViewModel ל-`BindingContext`. |
| `OnAppearing()` | כשהמסך עולה | ממקדת את המפה על אזור תחנות הקפה בצורה בטוחה דרך `Dispatcher.Dispatch`. |
| `OnPinMarkerClicked(object? sender, PinClickedEventArgs e)` | בלחיצה על **הסיכה עצמה** | מזהה את ה-`Pin` שנלחץ ומפעילה את `SelectStationByNameCommand` ב-ViewModel כדי לעדכן את פס המידע. |
| `OnPinInfoWindowClicked(object? sender, PinClickedEventArgs e)` | בלחיצה על **בועת המידע** מעל הסיכה | מעדכנת את התחנה הנבחרת ומציגה חלון פרטים מלא באמצעות `await DisplayAlertAsync(...)`. |

```csharp
using MauiGoogleMapSample.ViewModels;
using Microsoft.Maui.Controls.Maps;

namespace MauiGoogleMapSample.Views;

public partial class CoffeePinsPage : ContentPage
{
    private readonly CoffeePinsViewModel _viewModel;

    /// <summary>בנאי הדף: מקבל את ה-ViewModel מ-DI ומחבר ל-BindingContext.</summary>
    public CoffeePinsPage(CoffeePinsViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        BindingContext = _viewModel;
    }

    /// <summary>ממקד את המפה על תחנות הקפה בבטחה על ה-UI Thread בעליית המסך.</summary>
    protected override void OnAppearing()
    {
        base.OnAppearing();
        Dispatcher.Dispatch(() =>
        {
            try
            {
                PinsMapControl?.MoveToRegion(_viewModel.GetInitialMapSpan());
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[CoffeeMap] MoveToRegion skipped: {ex.Message}");
            }
        });
    }

    /// <summary>
    /// מופעל בלחיצה על הסיכה עצמה (ראו הסבר על "sender is Pin pin" בתיבה מתחת לקוד).
    /// </summary>
    private void OnPinMarkerClicked(object? sender, PinClickedEventArgs e)
    {
        if (sender is Pin pin)
        {
            _viewModel.SelectStationByNameCommand.Execute(pin.Label);
        }
    }

    /// <summary>
    /// מופעל בלחיצה על בועת המידע (Callout) שמעל הסיכה — פותח חלון פרטים אסינכרוני.
    /// </summary>
    private async void OnPinInfoWindowClicked(object? sender, PinClickedEventArgs e)
    {
        if (sender is Pin pin)
        {
            _viewModel.SelectStationByNameCommand.Execute(pin.Label);
            await DisplayAlertAsync(
                pin.Label,
                $"כתובת: {pin.Address}\n{_viewModel.SelectedStationBanner}",
                "סגור");
        }
    }
}
```

<div class="alert-important">
<strong>💡 תחביר C# למתחילים — מה זה <code>if (sender is Pin pin)</code>?</strong><br/>
באירועי UI, הפרמטר <code>sender</code> מגיע מטיפוס כללי <code>object?</code> (הפקד שלחצו עליו).<br/>
התנאי <code>if (sender is Pin pin)</code> (שנקרא <strong>Pattern Matching</strong>) עושה שתי פעולות יחד:<br/>
1. בודק אם <code>sender</code> הוא באמת אובייקט מסוג <code>Pin</code>.<br/>
2. אם כן — ממיר ושומר אותו אוטומטית במשתנה חדש בשם <code>pin</code> כך שנוכל לקרוא מיד ל-<code>pin.Label</code> ול-<code>pin.Address</code>!
</div>

---

## 7. שלב ה' — מה מוסיפים ב-`MauiProgram.cs` וב-`AppShell.xaml`?

### בתוך `MauiProgram.cs`:
```csharp
private static MauiAppBuilder RegisterServices(this MauiAppBuilder builder)
{
    builder.Services.AddSingleton<IMapConfigurationValidator, MapConfigurationValidator>();
    builder.Services.AddSingleton<ICoffeeRegionService, CoffeeRegionService>();
+   builder.Services.AddSingleton<ICoffeeStationService, CoffeeStationService>();
    return builder;
}

private static MauiAppBuilder RegisterViewModels(this MauiAppBuilder builder)
{
    builder.Services.AddTransient<SetupStatusViewModel>();
    builder.Services.AddTransient<MapDisplayViewModel>();
+   builder.Services.AddTransient<CoffeePinsViewModel>();
    return builder;
}

private static MauiAppBuilder RegisterViews(this MauiAppBuilder builder)
{
    builder.Services.AddTransient<MainPage>();
    builder.Services.AddTransient<MapDisplayPage>();
+   builder.Services.AddTransient<CoffeePinsPage>();
    return builder;
}
```

### בתוך `AppShell.xaml`:
```xml
    <FlyoutItem Title="שלב 2: תצוגת מפה וסוגים" Icon="icon_map.png">
        <ShellContent Title="שלב 2: תצוגת מפה" ContentTemplate="{DataTemplate views:MapDisplayPage}" Route="MapDisplayPage" />
    </FlyoutItem>
+   <FlyoutItem Title="שלב 3: סיכות (Pins)" Icon="icon_pins.png">
+       <ShellContent Title="שלב 3: סיכות" ContentTemplate="{DataTemplate views:CoffeePinsPage}" Route="CoffeePinsPage" />
+   </FlyoutItem>
```

---

## 8. אימות ובדיקות
בצעו **Build** והריצו את כל הבדיקות ב-Visual Studio (`Test -> Test Explorer -> Run All Tests`) או בטרמינל (`dotnet build` ו-`dotnet test`).  
למשימת התרגול שלכם, פתחו את [`Assignments/03-Pins-And-Callouts-Assignment.pdf`](Assignments/03-Pins-And-Callouts-Assignment.pdf).
