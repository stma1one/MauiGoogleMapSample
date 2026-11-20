using MauiGoogleMapSample.Models;
using Microsoft.Maui.Controls.Maps;
using Microsoft.Maui.Devices.Sensors;

namespace MauiGoogleMapSample.Services;

public interface ICoffeeRouteService
{
    Polyline BuildCoffeeTourPolyline(IEnumerable<CoffeeStation> stations);
    Circle BuildDeliveryZoneCircle(Location center, double radiusMeters);
    double CalculateTotalTourDistanceKm(IReadOnlyList<CoffeeStation> stations);
}
