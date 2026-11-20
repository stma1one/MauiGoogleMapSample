using MauiGoogleMapSample.Models;
using Microsoft.Maui.ApplicationModel;
using Microsoft.Maui.Devices.Sensors;

namespace MauiGoogleMapSample.Services;

public class LocationService : ILocationService
{
    public async Task<LocationFetchResult> GetCurrentLocationAsync()
    {
        try
        {
            PermissionStatus status = await Permissions.CheckStatusAsync<Permissions.LocationWhenInUse>();
            if (status != PermissionStatus.Granted)
            {
                status = await Permissions.RequestAsync<Permissions.LocationWhenInUse>();
            }

            if (status != PermissionStatus.Granted)
            {
                return new LocationFetchResult(
                    false,
                    false,
                    null,
                    "הרשאת מיקום נדחתה. יש לאשר גישה למיקום בהגדרות המכשיר כדי להציג את מיקומך על המפה.");
            }

            var request = new GeolocationRequest(GeolocationAccuracy.Medium, TimeSpan.FromSeconds(10));
            Location? location = await Geolocation.Default.GetLocationAsync(request);

            if (location is null)
            {
                return new LocationFetchResult(
                    false,
                    true,
                    null,
                    "לא ניתן היה לאתר את מיקום ה-GPS כרגע. ודאו ששירותי המיקום במכשיר מופעלים.");
            }

            return new LocationFetchResult(
                true,
                true,
                location,
                $"מיקום נוכחי: {location.Latitude:0.0000}, {location.Longitude:0.0000}");
        }
        catch (FeatureNotSupportedException)
        {
            return new LocationFetchResult(false, false, null, "מכשיר זה אינו תומך בשירותי GPS.");
        }
        catch (PermissionException)
        {
            return new LocationFetchResult(false, false, null, "חסרה הרשאת מיקום בזמן ריצה.");
        }
        catch (Exception ex)
        {
            return new LocationFetchResult(false, false, null, $"שגיאה בקבלת מיקום: {ex.Message}");
        }
    }

    public double CalculateDistanceKm(Location from, Location to)
    {
        ArgumentNullException.ThrowIfNull(from);
        ArgumentNullException.ThrowIfNull(to);
        return Location.CalculateDistance(from, to, DistanceUnits.Kilometers);
    }

    public (CoffeeStation? Station, double DistanceKm) FindNearestStation(Location userLocation, IEnumerable<CoffeeStation> stations)
    {
        ArgumentNullException.ThrowIfNull(userLocation);
        ArgumentNullException.ThrowIfNull(stations);

        CoffeeStation? nearest = null;
        double minDistance = double.MaxValue;

        foreach (CoffeeStation station in stations)
        {
            double distance = CalculateDistanceKm(userLocation, station.Location);
            if (distance < minDistance)
            {
                minDistance = distance;
                nearest = station;
            }
        }

        return nearest is null ? (null, 0) : (nearest, Math.Round(minDistance, 2));
    }
}
