# שלב 5: ציור מסלולים (`Polyline`) וצורות גיאוגרפיות (`Circle` / `Polygon`)

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git (Branch):** `stage/05-shapes-and-routes`  
> **קהל יעד:** תלמידים מתחילים בפיתוח אפליקציות מובייל (.NET MAUI)

---

## 1. מהם `MapElements` (שכבות וצורות על המפה)?

מעבר לסיכות (`Pins`), פקד ה-`Map` ב-.NET MAUI מאפשר לצייר **צורות גיאוגרפיות** מעל המפה באמצעות האוסף `Map.MapElements`:

| צורה (`MapElement`) | מבנה ושימוש | דוגמה באפליקציית CoffeeMap |
| :--- | :--- | :--- |
| **`Polyline`** | קו שבור המחבר רשימת נקודות (`Geopath`), עם `StrokeColor` ו-`StrokeWidth`. | ציור "מסלול סיור קפה" המחבר בין כל תחנות הקפה. |
| **`Circle`** | עיגול סביב נקודת `Center` ברדיוס `Radius`, עם `StrokeColor` ו-`FillColor`. | סימון "אזור משלוחים חינם" ברדיוס 800 מטר סביב התחנה הראשית. |
| **`Polygon`** | מצולע סגור (`Geopath`) עם קו מתאר ומילוי שקוף למחצה. | תיחום מתחם בתי קפה שלם (שכונה / מרכז מסחרי). |

---

## 2. איך יוצרים `Polyline` ו-`Circle` בקוד?

בשירות `Services/CoffeeRouteService.cs` יצרנו מתודות נקיות שבונות את האובייקטים:

```csharp
var polyline = new Polyline
{
    StrokeColor = Color.FromArgb("#6D4C41"),
    StrokeWidth = 8
};

foreach (CoffeeStation station in stations)
{
    polyline.Geopath.Add(station.Location);
}
```

ועיגול אזור משלוחים עם מילוי כחול שקוף למחצה (`#332563EB` — שתי הספרות הראשונות `33` הן שקיפות Alpha):

```csharp
new Circle
{
    Center = center,
    Radius = Distance.FromMeters(800),
    StrokeColor = Color.FromArgb("#2563EB"),
    StrokeWidth = 4,
    FillColor = Color.FromArgb("#332563EB")
};
```

---

## 3. הפרדת MVVM ובדיקת השכבות

`CoffeeRoutesViewModel` מנהל אילו שכבות פעילות (`ShowRoute`, `ShowDeliveryZone`), מחשב את האורך הכולל של מסלול הקפה (`TotalTourDistanceKm`), ומחזיר את הרשימה דרך `BuildActiveMapElements()`.  
הדף `CoffeeRoutesPage.xaml.cs` מאזין ל-`MapElementsChanged` ומעדכן את `RoutesMapControl.MapElements`.

* להרצת כל בדיקות היחידה בפרויקט: ב-Visual Studio לחצו `Test -> Test Explorer -> Run All Tests`, או בטרמינל הריצו `dotnet build` ו-`dotnet test`.

למשימת הסיום שלכם, פתחו את [`Docs/Assignments/05-Shapes-And-Routes-Assignment.pdf`](Assignments/05-Shapes-And-Routes-Assignment.pdf).
