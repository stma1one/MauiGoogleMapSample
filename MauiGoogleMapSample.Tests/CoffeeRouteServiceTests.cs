using MauiGoogleMapSample.Models;
using MauiGoogleMapSample.Services;
using Microsoft.Maui.Controls.Maps;
using Microsoft.Maui.Devices.Sensors;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class CoffeeRouteServiceTests
{
    [Fact]
    public void BuildCoffeeTourPolyline_ContainsOneGeopathPointPerStation()
    {
        // Arrange
        var stationService = new CoffeeStationService();
        var routeService = new CoffeeRouteService();
        IReadOnlyList<CoffeeStation> stations = stationService.GetStations();

        // Act
        Polyline polyline = routeService.BuildCoffeeTourPolyline(stations);

        // Assert
        Assert.Equal(stations.Count, polyline.Geopath.Count);
        Assert.True(polyline.StrokeWidth > 0);
    }

    [Fact]
    public void BuildDeliveryZoneCircle_ClampsSmallRadiusToMinimum50Meters()
    {
        // Arrange
        var routeService = new CoffeeRouteService();
        var center = new Location(32.0636, 34.7731);

        // Act
        Circle circle = routeService.BuildDeliveryZoneCircle(center, 10);

        // Assert
        Assert.Equal(50, circle.Radius.Meters, 1);
        Assert.Equal(center, circle.Center);
    }

    [Fact]
    public void CalculateTotalTourDistanceKm_ReturnsPositiveDistanceForMultipleStations()
    {
        // Arrange
        var stationService = new CoffeeStationService();
        var routeService = new CoffeeRouteService();

        // Act
        double totalKm = routeService.CalculateTotalTourDistanceKm(stationService.GetStations());

        // Assert
        Assert.True(totalKm > 4.0 && totalKm < 10.0);
    }
}
