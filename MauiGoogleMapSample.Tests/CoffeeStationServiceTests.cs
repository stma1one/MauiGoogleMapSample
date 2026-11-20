using MauiGoogleMapSample.Models;
using MauiGoogleMapSample.Services;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class CoffeeStationServiceTests
{
    [Fact]
    public void GetStations_ReturnsFourStationsWithValidLocations()
    {
        // Arrange
        var service = new CoffeeStationService();

        // Act
        IReadOnlyList<CoffeeStation> stations = service.GetStations();

        // Assert
        Assert.Equal(4, stations.Count);
        Assert.All(stations, s =>
        {
            Assert.False(string.IsNullOrWhiteSpace(s.Name));
            Assert.True(s.Location.Latitude > 30 && s.Location.Longitude > 34);
        });
    }

    [Fact]
    public void FilterStations_BySpecialty_ReturnsMatchingStationsOnly()
    {
        // Arrange
        var service = new CoffeeStationService();

        // Act
        IReadOnlyList<CoffeeStation> matches = service.FilterStations("אספרסו");

        // Assert
        Assert.Equal(2, matches.Count);
        Assert.All(matches, s => Assert.Contains("אספרסו", s.Specialty));
    }

    [Fact]
    public void FilterStations_WhenQueryEmpty_ReturnsAllStations()
    {
        // Arrange
        var service = new CoffeeStationService();

        // Act
        IReadOnlyList<CoffeeStation> all = service.FilterStations("  ");

        // Assert
        Assert.Equal(4, all.Count);
    }
}
