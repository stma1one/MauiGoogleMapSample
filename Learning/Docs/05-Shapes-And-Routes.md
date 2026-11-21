# שלב 5: ציור מסלולים (`Polyline`) וצורות גיאוגרפיות (`Circle` / `Polygon`)

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git (Branch):** `stage/05-shapes-and-routes`  
> **קהל יעד:** תלמידים מתחילים בפיתוח אפליקציות מובייל (.NET MAUI)  
> **מקרא צבעים בקוד:** שורות המודגשות ב**רקע ירוק וטקסט צהוב** הן שורות חדשות שיש להוסיף לתוך קובץ קיים.

---

## 1. מה אנחנו בונים בשלב הזה? (תצוגת המסך)

בשלב זה נבנה צעד אחר צעד את מסך **`CoffeeRoutesPage`** שמצייר מעל המפה **מסלול סיור קפה (`Polyline`)** המחבר בין כל תחנות הקפה ו**אזור משלוחים (`Circle`)** ברדיוס 800 מטר, מחשב את אורך המסלול הכולל (`5.97 ק"מ`), ומאפשר להדליק, לכבות ולנקות שכבות:

![תצוגת מסך שלב 5 (צילום חי מאימולטור Android) - CoffeeRoutesPage](../../Learning/Images/CoffeeRoutesPage-live.png)

> **שימו לב:** כמו בשלבים הקודמים, אריחי המפה והשכבות הגרפיות יוצגו במלואם לאחר הצבת מפתח Google Maps API אמיתי בקובץ המקומי `Secrets.props` (ראו מדריך `01b`).

---

## 2. מה מובנה ב-.NET MAUI לעומת מה אנחנו יוצרים בעצמנו?

| רכיב | מאיפה הוא מגיע? | תפקיד |
| :--- | :--- | :--- |
| `Map.MapElements` | **מובנה ב-`<maps:Map>`** | האוסף שאליו מוסיפים צורות גיאוגרפיות לציור מעל המפה. |
| `Polyline`, `Circle`, `Polygon` | **מובנה ב-`Microsoft.Maui.Controls.Maps`** | מחלקות הצורות (`Geopath`, `Center`, `Radius`, `StrokeColor`, `FillColor`). |
| `Color.FromArgb("#332563EB")` | **מובנה ב-`Microsoft.Maui.Graphics`** | יצירת צבע כולל שקיפות (Alpha) לצביעת צורות. |
| `Dispatcher.Dispatch(...)` | **מובנה ב-`ContentPage` (.NET MAUI)** | מתזמן את עדכון שכבות המפה בבטחה על ה-UI Thread. |
| `ICoffeeRouteService` / `CoffeeRouteService` | **מחלקה שיצרנו בעצמנו (`Services/`)** | בונה את אובייקטי ה-`Polyline` וה-`Circle` ומחשבת את אורך המסלול. |
| `CoffeeRoutesViewModel` + האירוע `MapElementsChanged` | **מחלקה ואירוע שיצרנו בעצמנו (`ViewModels/`)** | מנהלת אילו שכבות פעילות ומודיעה לדף מתי לצייר מחדש את `MapElements`. |

---

## 3. שלב א' — ממשק השירות ובניית הצורות (`Services`)

### 3.1 ממשק השירות (`Services/ICoffeeRouteService.cs`)
```csharp
using MauiGoogleMapSample.Models;
using Microsoft.Maui.Controls.Maps;
using Microsoft.Maui.Devices.Sensors;

namespace MauiGoogleMapSample.Services;

/// <summary>
/// חוזה לשירות שבונה שכבות גיאוגרפיות (Polyline / Circle) ומחשב את אורך מסלול הקפה.
/// </summary>
public interface ICoffeeRouteService
{
    /// <summary>יוצר קו מסלול (Polyline) המחבר את כל תחנות הקפה לפי סדרן.</summary>
    Polyline BuildCoffeeTourPolyline(IEnumerable<CoffeeStation> stations);

    /// <summary>יוצר עיגול (Circle) לסימון אזור משלוחים סביב נקודת מרכז ורדיוס במטרים.</summary>
    Circle BuildDeliveryZoneCircle(Location center, double radiusMeters);

    /// <summary>מחשב את האורך הכולל בקילומטרים של סיור בין כל התחנות.</summary>
    double CalculateTotalTourDistanceKm(IReadOnlyList<CoffeeStation> stations);
}
```

### 3.2 מימוש השירות (`Services/CoffeeRouteService.cs`)
```csharp
public class CoffeeRouteService : ICoffeeRouteService
{
    /// <summary>מחבר את קואורדינטות התחנות לתוך אוסף הנקודות Geopath של ה-Polyline.</summary>
    public Polyline BuildCoffeeTourPolyline(IEnumerable<CoffeeStation> stations)
    {
        ArgumentNullException.ThrowIfNull(stations);

        var polyline = new Polyline
        {
            StrokeColor = Color.FromArgb("#6D4C41"),
            StrokeWidth = 8
        };

        foreach (CoffeeStation station in stations)
        {
            polyline.Geopath.Add(station.Location);
        }
        return polyline;
    }

    /// <summary>יוצר עיגול אזור משלוחים עם הגנה מפני רדיוס קטן מ-50 מטר.</summary>
    public Circle BuildDeliveryZoneCircle(Location center, double radiusMeters)
    {
        ArgumentNullException.ThrowIfNull(center);

        // ראו הסבר על אופרטור ? : ועל צבע שקוף #AARRGGBB בתיבה מתחת לקוד
        double safeRadius = radiusMeters < 50 ? 50 : radiusMeters;

        return new Circle
        {
            Center = center,
            Radius = Distance.FromMeters(safeRadius),
            StrokeColor = Color.FromArgb("#2563EB"),
            StrokeWidth = 4,
            FillColor = Color.FromArgb("#332563EB")
        };
    }

    /// <summary>עובר על כל זוג תחנות סמוכות (i ו-i+1) וסוכם את המרחק ביניהן בק"מ.</summary>
    public double CalculateTotalTourDistanceKm(IReadOnlyList<CoffeeStation> stations)
    {
        ArgumentNullException.ThrowIfNull(stations);
        if (stations.Count < 2) return 0;

        double totalKm = 0;
        for (int i = 0; i < stations.Count - 1; i++)
        {
            totalKm += Location.CalculateDistance(
                stations[i].Location,
                stations[i + 1].Location,
                DistanceUnits.Kilometers);
        }
        return Math.Round(totalKm, 2);
    }
}
```

<div class="alert-important">
<strong>💡 תחביר C# וגרפיקה למתחילים — אופרטור <code>? :</code> וצבעים עם שקיפות (<code>#AARRGGBB</code>):</strong><br/>
• <strong><code>double safeRadius = radiusMeters &lt; 50 ? 50 : radiusMeters;</code></strong> — נקרא <strong>Ternary Operator</strong> (תנאי מקוצר בשורה אחת): אם <code>radiusMeters</code> קטן מ-50 השתמש ב-50, אחרת השתמש ב-<code>radiusMeters</code>.<br/>
• <strong><code>#332563EB</code></strong> — קוד צבע בן 8 תווים בפורמט <code>#AARRGGBB</code>: שתי הספרות הראשונות (<code>33</code>) קובעות <strong>שקיפות (Alpha ~20%)</strong> כדי שאפשר יהיה לראות את הרחובות של המפה מבעד לעיגול הכחול!
</div>

---

## 4. שלב ב' — בניית ה-ViewModel שלב אחר שלב (`ViewModels/CoffeeRoutesViewModel.cs`)

### צעד 1: הגדרת המחלקה והבנאי (`Constructor`)
ה-ViewModel מקבל שני שירותים ב-DI (`ICoffeeStationService` ו-`ICoffeeRouteService`), טוען את התחנות, מחשב את אורך המסלול הכולל ומאתחל את 3 הפקודות:

```csharp
public class CoffeeRoutesViewModel : BaseViewModel
{
    private readonly ICoffeeStationService _stationService;
    private readonly ICoffeeRouteService _routeService;
    private bool _showRoute = true;
    private bool _showDeliveryZone = true;

    public CoffeeRoutesViewModel(ICoffeeStationService stationService, ICoffeeRouteService routeService)
    {
        _stationService = stationService;
        _routeService = routeService;
        Title = "CoffeeMap — שלב 5: מסלולים וצורות";

        IReadOnlyList<CoffeeStation> stations = _stationService.GetStations();
        Stations = new ObservableCollection<CoffeeStation>(stations);
        _totalTourDistanceKm = _routeService.CalculateTotalTourDistanceKm(stations);

        _toggleRouteCommand = new Command(ExecuteToggleRoute);
        _toggleDeliveryZoneCommand = new Command(ExecuteToggleDeliveryZone);
        _clearOverlaysCommand = new Command(ExecuteClearOverlays, CanExecuteClearOverlays);
        UpdateRouteSummary();
    }
}
```

### צעד 2: טבלת כל ה-Properties ב-`CoffeeRoutesViewModel` והשימוש בהם

| מאפיין (`Property`) | טיפוס | תפקיד ושימוש ב-XAML / לוגיקה |
| :--- | :--- | :--- |
| `Title` (מורש מ-`BaseViewModel`) | `string` | כותרת הדף בסרגל העליון. |
| `Stations` | `ObservableCollection<CoffeeStation>` | תחנות הקפה המוצגות כסיכות ומשמשות נקודות למסלול. |
| `ShowRoute` | `bool` | האם שכבת ה-`Polyline` פעילה — מעדכן `ClearOverlaysCommand` ומפעיל `MapElementsChanged`. |
| `ShowDeliveryZone` | `bool` | האם שכבת ה-`Circle` פעילה — מעדכן `ClearOverlaysCommand` ומפעיל `MapElementsChanged`. |
| `TotalTourDistanceKm` | `double` | האורך הכולל של סיור הקפה בקילומטרים (`5.97`). |
| `RouteSummary` | `string` | שורת הסיכום בתחתית המסך (`Label Text="{Binding RouteSummary}"`). |

```csharp
public bool ShowRoute
{
    get => _showRoute;
    set
    {
        if (_showRoute == value) return;
        _showRoute = value;
        OnPropertyChanged();
        _clearOverlaysCommand.ChangeCanExecute();
        UpdateRouteSummary();
        MapElementsChanged?.Invoke(); // מודיע לדף לצייר מחדש את שכבות המפה
    }
}
```

### צעד 3: הפקודות (`ICommand`) ותנאי `CanExecute`
* `ToggleRouteCommand` — הופך את `ShowRoute = !ShowRoute`.
* `ToggleDeliveryZoneCommand` — הופך את `ShowDeliveryZone = !ShowDeliveryZone`.
* `ClearOverlaysCommand` — מאפס את שניהם ל-`false`, ופעיל (`CanExecute`) רק כאשר `ShowRoute || ShowDeliveryZone` (כך הכפתור מושבת אוטומטית כשאין שכבות פעילות!).

### צעד 4: ה-Event שלנו `MapElementsChanged` ומתודת `BuildActiveMapElements()`
```csharp
// Event שיצרנו בעצמנו (לא של פקד המפה!) כדי להודיע לדף מתי לעדכן את MapElements
public event Action? MapElementsChanged;

public IReadOnlyList<MapElement> BuildActiveMapElements()
{
    var elements = new List<MapElement>();

    if (ShowRoute && Stations.Count >= 2)
        elements.Add(_routeService.BuildCoffeeTourPolyline(Stations));

    if (ShowDeliveryZone && Stations.Count > 0)
        elements.Add(_routeService.BuildDeliveryZoneCircle(Stations[0].Location, 800));

    return elements;
}
```

---

## 5. שלב ג' — בניית ה-XAML שלב אחר שלב (`Views/CoffeeRoutesPage.xaml`)

### צעד 1: הגדרת כותרת ה-`ContentPage` ומרחבי השמות (`xmlns`)
```xml
<ContentPage xmlns="http://schemas.microsoft.com/dotnet/2021/maui"
             xmlns:x="http://schemas.microsoft.com/winfx/2009/xaml"
+            xmlns:maps="http://schemas.microsoft.com/dotnet/2021/maui/maps"
+            xmlns:models="clr-namespace:MauiGoogleMapSample.Models"
+            xmlns:vm="clr-namespace:MauiGoogleMapSample.ViewModels"
             x:Class="MauiGoogleMapSample.Views.CoffeeRoutesPage"
+            x:DataType="vm:CoffeeRoutesViewModel"
+            FlowDirection="RightToLeft"
             Title="{Binding Title}">
```

### צעד 2: חלוקת המסך (`Grid`), כפתורי השכבות (`Row 0`), המפה (`Row 1`) ופס הסיכום (`Row 2`)
```xml
<Grid RowDefinitions="Auto,*,Auto" RowSpacing="8" Padding="12">
    <!-- Row 0: כפתורי הדלקה/כיבוי של השכבות -->
    <HorizontalStackLayout Grid.Row="0" Spacing="8" HorizontalOptions="Center">
        <Button Text="מסלול קפה" Command="{Binding ToggleRouteCommand}" />
        <Button Text="אזור משלוח" Command="{Binding ToggleDeliveryZoneCommand}" />
        <Button Text="נקה שכבות" Command="{Binding ClearOverlaysCommand}" BackgroundColor="{StaticResource Gray500}" />
    </HorizontalStackLayout>

    <!-- Row 1: המפה עם הסיכות (ה-Polyline וה-Circle מתווספים ל-MapElements ב-xaml.cs) -->
    <Border Grid.Row="1" StrokeShape="RoundRectangle 12" Stroke="{StaticResource Gray300}">
        <maps:Map x:Name="RoutesMapControl" ItemsSource="{Binding Stations}" IsScrollEnabled="True" IsZoomEnabled="True">
            <maps:Map.ItemTemplate>
                <DataTemplate x:DataType="models:CoffeeStation">
                    <maps:Pin Location="{Binding Location}" Label="{Binding Name}" Address="{Binding Address}" Type="Place" />
                </DataTemplate>
            </maps:Map.ItemTemplate>
        </maps:Map>
    </Border>

    <!-- Row 2: פס סיכום אורך המסלול והשכבות הפעילות -->
    <Border Grid.Row="2" StrokeShape="RoundRectangle 8" Padding="12" BackgroundColor="{StaticResource Gray100}">
        <Label Text="{Binding RouteSummary}" FontSize="13" FontAttributes="Bold" HorizontalTextAlignment="Center" />
    </Border>
</Grid>
```

---

## 6. שלב ד' — בניית ה-Code-Behind שלב אחר שלב (`Views/CoffeeRoutesPage.xaml.cs`)

### פירוט כל הפעולות ב-`CoffeeRoutesPage.xaml.cs`:

| פעולה (`Method`) | מתי היא מופעלת? | מה היא עושה ולמה היא חשובה? |
| :--- | :--- | :--- |
| `CoffeeRoutesPage(CoffeeRoutesViewModel viewModel)` | בעת יצירת הדף (DI) | טוענת את ה-XAML ומחברת את ה-ViewModel ל-`BindingContext`. |
| `OnAppearing()` | כשהמסך עולה | נרשמת (`+=`) ל-`MapElementsChanged`, ממקדת את המפה ומציירת את השכבות הראשוניות דרך `Dispatcher.Dispatch`. |
| `OnDisappearing()` | כשהמשתמש עוזב את המסך | מבטלת רישום (`-=`) מהאירוע כדי למנוע **Memory Leak**. |
| `RefreshMapElements()` | בעליית המסך ובכל שינוי שכבה | מנקה את `RoutesMapControl.MapElements` ומוסיפה מחדש רק את האלמנטים הפעילים מתוך `_viewModel.BuildActiveMapElements()`. |

```csharp
using MauiGoogleMapSample.ViewModels;
using Microsoft.Maui.Controls.Maps;

namespace MauiGoogleMapSample.Views;

public partial class CoffeeRoutesPage : ContentPage
{
    private readonly CoffeeRoutesViewModel _viewModel;

    /// <summary>בנאי הדף: מקבל את ה-ViewModel מ-DI ומחבר ל-BindingContext.</summary>
    public CoffeeRoutesPage(CoffeeRoutesViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        BindingContext = _viewModel;
    }

    /// <summary>נרשם לאירוע שינוי השכבות, ממקד את המפה ומצייר את השכבות על ה-UI Thread.</summary>
    protected override void OnAppearing()
    {
        base.OnAppearing();
        _viewModel.MapElementsChanged += RefreshMapElements;
        Dispatcher.Dispatch(() =>
        {
            try
            {
                RoutesMapControl?.MoveToRegion(_viewModel.GetInitialMapSpan());
                RefreshMapElements();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[CoffeeMap] Route map init skipped: {ex.Message}");
            }
        });
    }

    /// <summary>מבטל רישום מהאירוע בעת יציאה מהמסך למניעת דליפת זיכרון.</summary>
    protected override void OnDisappearing()
    {
        _viewModel.MapElementsChanged -= RefreshMapElements;
        base.OnDisappearing();
    }

    /// <summary>מרענן את אוסף RoutesMapControl.MapElements לפי השכבות הפעילות ב-ViewModel.</summary>
    private void RefreshMapElements()
    {
        Dispatcher.Dispatch(() =>
        {
            try
            {
                if (RoutesMapControl is null) return;
                RoutesMapControl.MapElements.Clear();
                foreach (MapElement element in _viewModel.BuildActiveMapElements())
                {
                    RoutesMapControl.MapElements.Add(element);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[CoffeeMap] RefreshMapElements skipped: {ex.Message}");
            }
        });
    }
}
```

---

## 7. שלב ה' — מה מוסיפים ב-`MauiProgram.cs` וב-`AppShell.xaml`?

### בתוך `MauiProgram.cs`:
```csharp
private static MauiAppBuilder RegisterServices(this MauiAppBuilder builder)
{
    builder.Services.AddSingleton<IMapConfigurationValidator, MapConfigurationValidator>();
    builder.Services.AddSingleton<ICoffeeRegionService, CoffeeRegionService>();
    builder.Services.AddSingleton<ICoffeeStationService, CoffeeStationService>();
    builder.Services.AddSingleton<ILocationService, LocationService>();
+   builder.Services.AddSingleton<ICoffeeRouteService, CoffeeRouteService>();
    return builder;
}

private static MauiAppBuilder RegisterViewModels(this MauiAppBuilder builder)
{
    builder.Services.AddTransient<SetupStatusViewModel>();
    builder.Services.AddTransient<MapDisplayViewModel>();
    builder.Services.AddTransient<CoffeePinsViewModel>();
    builder.Services.AddTransient<UserLocationViewModel>();
+   builder.Services.AddTransient<CoffeeRoutesViewModel>();
    return builder;
}

private static MauiAppBuilder RegisterViews(this MauiAppBuilder builder)
{
    builder.Services.AddTransient<MainPage>();
    builder.Services.AddTransient<MapDisplayPage>();
    builder.Services.AddTransient<CoffeePinsPage>();
    builder.Services.AddTransient<UserLocationPage>();
+   builder.Services.AddTransient<CoffeeRoutesPage>();
    return builder;
}
```

### בתוך `AppShell.xaml`:
```xml
    <FlyoutItem Title="שלב 4: מיקום GPS" Icon="icon_gps.png">
        <ShellContent Title="שלב 4: מיקום GPS" ContentTemplate="{DataTemplate views:UserLocationPage}" Route="UserLocationPage" />
    </FlyoutItem>
+   <FlyoutItem Title="שלב 5: מסלולים וצורות" Icon="icon_routes.png">
+       <ShellContent Title="שלב 5: מסלולים וצורות" ContentTemplate="{DataTemplate views:CoffeeRoutesPage}" Route="CoffeeRoutesPage" />
+   </FlyoutItem>
```

---

## 8. אימות ובדיקות
בצעו **Build** והריצו את כל הבדיקות ב-Visual Studio (`Test -> Test Explorer -> Run All Tests`) או בטרמינל (`dotnet build` ו-`dotnet test`).  
למשימת הסיום שלכם (ציור `Polygon` למתחם הקפה), פתחו את [`Assignments/05-Shapes-And-Routes-Assignment.pdf`](Assignments/05-Shapes-And-Routes-Assignment.pdf).
