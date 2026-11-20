using MauiGoogleMapSample.Models;
using Microsoft.Maui.Devices.Sensors;
using Microsoft.Maui.Maps;

namespace MauiGoogleMapSample.Services;

public class CoffeeRegionService : ICoffeeRegionService
{
    public IReadOnlyList<CoffeeRegion> GetDefaultRegions()
    {
        return new List<CoffeeRegion>
        {
            new()
            {
                Name = "תל אביב — רוטשילד",
                Description = "שדרת בתי הקפה המרכזית של תל אביב",
                Latitude = 32.0636,
                Longitude = 34.7731,
                DefaultRadiusKm = 1.2
            },
            new()
            {
                Name = "ירושלים — מחנה יהודה",
                Description = "תחנות קפה מיוחדות סביב השוק",
                Latitude = 31.7850,
                Longitude = 35.2124,
                DefaultRadiusKm = 1.5
            },
            new()
            {
                Name = "חיפה — המושבה הגרמנית",
                Description = "בתי קפה מול הגנים הבהאיים",
                Latitude = 32.8191,
                Longitude = 34.9912,
                DefaultRadiusKm = 1.8
            }
        };
    }

    public MapSpan BuildMapSpan(CoffeeRegion region, double? overrideRadiusKm = null)
    {
        ArgumentNullException.ThrowIfNull(region);

        double radiusKm = overrideRadiusKm ?? region.DefaultRadiusKm;
        if (radiusKm < 0.2)
        {
            radiusKm = 0.2;
        }
        else if (radiusKm > 25.0)
        {
            radiusKm = 25.0;
        }

        var center = new Location(region.Latitude, region.Longitude);
        return MapSpan.FromCenterAndRadius(center, Distance.FromKilometers(radiusKm));
    }
}
