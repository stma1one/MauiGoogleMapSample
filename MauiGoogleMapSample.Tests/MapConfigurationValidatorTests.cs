using MauiGoogleMapSample.Services;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class MapConfigurationValidatorTests
{
    [Fact]
    public void ValidateApiKey_WhenNullOrEmpty_ReturnsInvalid()
    {
        // Arrange
        var validator = new MapConfigurationValidator();

        // Act
        MapConfigCheckResult result = validator.ValidateApiKey("   ");

        // Assert
        Assert.False(result.IsValid);
        Assert.Contains("חסר", result.StatusTitle);
    }

    [Fact]
    public void ValidateApiKey_WhenPlaceholder_ReturnsInvalidWithPlaceholderMessage()
    {
        // Arrange
        var validator = new MapConfigurationValidator();

        // Act
        MapConfigCheckResult result = validator.ValidateApiKey(validator.PlaceholderKey);

        // Assert
        Assert.False(result.IsValid);
        Assert.Contains("Placeholder", result.StatusTitle);
    }

    [Fact]
    public void ValidateApiKey_WhenTooShort_ReturnsInvalid()
    {
        // Arrange
        var validator = new MapConfigurationValidator();

        // Act
        MapConfigCheckResult result = validator.ValidateApiKey("AIzaShort123");

        // Assert
        Assert.False(result.IsValid);
        Assert.Contains("קצר", result.StatusTitle);
    }

    [Fact]
    public void ValidateApiKey_WhenValidLength_ReturnsValid()
    {
        // Arrange
        var validator = new MapConfigurationValidator();

        // Act
        MapConfigCheckResult result = validator.ValidateApiKey("AIzaSyFakeExampleKeyForUnitTests123456");

        // Assert
        Assert.True(result.IsValid);
        Assert.Contains("תקין", result.StatusTitle);
    }
}
