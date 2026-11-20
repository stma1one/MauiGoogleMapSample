using MauiGoogleMapSample.Models;
using MauiGoogleMapSample.Services;
using Microsoft.Maui.Maps;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class CoffeeRegionServiceTests
{
    [Fact]
    public void GetDefaultRegions_ReturnsThreeIsraeliCoffeeHubs()
    {
        // Arrange
        var service = new CoffeeRegionService();

        // Act
        IReadOnlyList<CoffeeRegion> regions = service.GetDefaultRegions();

        // Assert
        Assert.Equal(3, regions.Count);
        Assert.Contains(regions, r => r.Name.Contains("תל אביב"));
        Assert.Contains(regions, r => r.Name.Contains("ירושלים"));
        Assert.Contains(regions, r => r.Name.Contains("חיפה"));
    }

    [Fact]
    public void BuildMapSpan_ReturnsSpanCenteredOnRegionCoordinates()
    {
        // Arrange
        var service = new CoffeeRegionService();
        CoffeeRegion telAviv = service.GetDefaultRegions()[0];

        // Act
        MapSpan span = service.BuildMapSpan(telAviv, 2.0);

        // Assert
        Assert.Equal(telAviv.Latitude, span.Center.Latitude, 4);
        Assert.Equal(telAviv.Longitude, span.Center.Longitude, 4);
        Assert.InRange(span.Radius.Kilometers, 1.9, 2.1);
    }

    [Fact]
    public void BuildMapSpan_WhenRadiusTooSmall_ClampsToMinimum()
    {
        // Arrange
        var service = new CoffeeRegionService();
        CoffeeRegion region = service.GetDefaultRegions()[0];

        // Act
        MapSpan span = service.BuildMapSpan(region, 0.01);

        // Assert
        Assert.InRange(span.Radius.Kilometers, 0.19, 0.21);
    }
}
