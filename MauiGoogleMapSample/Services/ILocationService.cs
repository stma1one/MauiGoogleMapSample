using MauiGoogleMapSample.Models;
using Microsoft.Maui.Devices.Sensors;

namespace MauiGoogleMapSample.Services;

public record LocationFetchResult(bool IsSuccess, bool PermissionGranted, Location? Location, string Message);

public interface ILocationService
{
    Task<LocationFetchResult> GetCurrentLocationAsync();
    double CalculateDistanceKm(Location from, Location to);
    (CoffeeStation? Station, double DistanceKm) FindNearestStation(Location userLocation, IEnumerable<CoffeeStation> stations);
}
