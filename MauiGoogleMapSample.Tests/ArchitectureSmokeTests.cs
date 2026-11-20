using Xunit;

namespace MauiGoogleMapSample.Tests;

/// <summary>
/// בדיקת שפיות ראשונית (Smoke Test) המאמתת שתשתית ה-xUnit מוגדרת ומקושרת לפרויקט.
/// בכל סלייס חדש יש להוסיף מחלקות בדיקה עבור ViewModels, Services ו-Converters לפי תבנית Arrange-Act-Assert.
/// </summary>
public class ArchitectureSmokeTests
{
    [Fact]
    public void TestHarness_WhenInitialized_PassesSanityCheck()
    {
        // Arrange (הכנת נתוני הבדיקה)
        const int expectedMinimumTests = 1;

        // Act (הפעלת הלוגיקה הנבדקת)
        int actualConfiguredTests = 1;

        // Assert (אימות שהתוצאה בפועל תואמת למצופה)
        Assert.True(actualConfiguredTests >= expectedMinimumTests);
    }
}
