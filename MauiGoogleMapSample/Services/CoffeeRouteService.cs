using MauiGoogleMapSample.Models;
using Microsoft.Maui.Controls.Maps;
using Microsoft.Maui.Devices.Sensors;
using Microsoft.Maui.Graphics;
using Microsoft.Maui.Maps;

namespace MauiGoogleMapSample.Services;

public class CoffeeRouteService : ICoffeeRouteService
{
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

    public Circle BuildDeliveryZoneCircle(Location center, double radiusMeters)
    {
        ArgumentNullException.ThrowIfNull(center);
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
