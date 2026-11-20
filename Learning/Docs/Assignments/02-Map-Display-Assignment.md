# משימה 2: הוספת אזור קפה חדש וכפתור איפוס זום (`ResetZoomCommand`)

> **פרויקט:** CoffeeMap — מפת תחנות קפה ב-.NET MAUI  
> **ענף Git בסיס:** `stage/02-map-display-and-types`  
> **זמן משוער:** 35–45 דקות

---

## מטרת המשימה
לתרגל עבודה עם מודלים של אזורי מפה (`CoffeeRegion`), פקודות `ICommand` ב-ViewModel (`MapDisplayViewModel`), קישור כפתורים ב-XAML (`Binding`), וכתיבת בדיקות יחידה ב-`xunit.v3`.

> **טיפ:** אם אתם צריכים תזכורת איך מריצים וכותבים בדיקות, פתחו את [`00-Working-With-Unit-Tests.pdf`](../00-Working-With-Unit-Tests.pdf).

---

## חלק א': הוספת אזור קפה רביעי (עיר לבחירתכם)

1. פתחו את הקובץ `MauiGoogleMapSample/Services/CoffeeRegionService.cs`.
2. בתוך המתודה `GetDefaultRegions()`, הוסיפו אובייקט `CoffeeRegion` רביעי לעיר שלכם או לעיר מוכרת בישראל (לדוגמה: **באר שבע — העיר העתיקה** בקואורדינטות `Latitude = 31.2439`, `Longitude = 34.7913`, `DefaultRadiusKm = 1.5`).
3. עדכנו את הבדיקה `GetDefaultRegions_ReturnsThreeIsraeliCoffeeHubs` בקובץ `MauiGoogleMapSample.Tests/CoffeeRegionServiceTests.cs` כך שתבדוק שיש כעת **4** אזורים ושהאזור החדש שלכם כלול ברשימה.

---

## חלק ב': הוספת פקודת איפוס זום (`ResetZoomCommand`) ב-ViewModel

כרגע המשתמש יכול לעשות זום פנימה (`+`) והחוצה (`-`), אבל אין כפתור שמחזיר במהירות את הזום לרדיוס ברירת המחדל של האזור הנבחר (`SelectedRegion.DefaultRadiusKm`).

1. פתחו את `MauiGoogleMapSample/ViewModels/MapDisplayViewModel.cs`.
2. הוסיפו שדה ומאפיין לפקודה חדשה:
   ```csharp
   private readonly Command _resetZoomCommand;
   public ICommand ResetZoomCommand => _resetZoomCommand;
   ```
3. אתחלו אותה בבנאי (`Constructor`) עם מתודת ביצוע `ExecuteResetZoom` ותנאי `CanExecuteResetZoom`:
   * **`CanExecuteResetZoom()`** — מחזירה `true` רק כאשר `ZoomRadiusKm` **שונה** מ-`SelectedRegion.DefaultRadiusKm` (כלומר `Math.Abs(ZoomRadiusKm - SelectedRegion.DefaultRadiusKm) > 0.01`).
   * **`ExecuteResetZoom()`** — מחזירה את `ZoomRadiusKm = SelectedRegion.DefaultRadiusKm;` וקוראת ל-`RequestMapMove();`.
4. אל תשכחו לקרוא ל-`_resetZoomCommand.ChangeCanExecute()` בתוך ה-`set` של `ZoomRadiusKm` ושל `SelectedRegion`!

---

## חלק ג': הוספת הכפתור במסך (`MapDisplayPage.xaml`)

1. פתחו את `MauiGoogleMapSample/Views/MapDisplayPage.xaml`.
2. בשורה העליונה (`Grid.Row="0"`), ליד כפתורי `+` ו-`-`, הוסיפו כפתור חדש:
   ```xml
   <Button AutomationId="ResetZoomButton"
           Text="איפוס זום"
           Command="{Binding ResetZoomCommand}" />
   ```
3. שימו לב שאין צורך ב-`IsEnabled` — מנגנון ה-`CanExecute` של ה-`ICommand` ישבית ויאפשר את הכפתור אוטומטית!

---

## חלק ד': כתיבת בדיקת יחידה ואימות

1. פתחו את `MauiGoogleMapSample.Tests/MapDisplayViewModelTests.cs`.
2. הוסיפו בדיקה חדשה בשם `ResetZoomCommand_AfterZoomIn_RestoresDefaultRadiusAndDisablesItself`:
   * **Arrange:** צרו `MapDisplayViewModel` עם `CoffeeRegionService`. ודאו שבהתחלה `vm.ResetZoomCommand.CanExecute(null)` הוא `false`.
   * **Act:** הפעילו `vm.ZoomInCommand.Execute(null)` (ודאו שכעת `CanExecute` הפך ל-`true`), ואז הפעילו `vm.ResetZoomCommand.Execute(null)`.
   * **Assert:** ודאו ש-`vm.ZoomRadiusKm` חזר ל-`vm.SelectedRegion.DefaultRadiusKm`, וש-`vm.ResetZoomCommand.CanExecute(null)` חזר להיות `false`.
3. בצעו **Build** והריצו את כל הבדיקות:
   * ב-Visual Studio: `Build -> Build Solution`, ואז `Test -> Test Explorer -> Run All Tests`.
   * או בטרמינל:
     ```powershell
     dotnet build
     dotnet test
     ```
   וודאו שכל הבדיקות עוברות (`Failed: 0`)!
