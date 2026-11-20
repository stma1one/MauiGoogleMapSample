using MauiGoogleMapSample.Models;

namespace MauiGoogleMapSample.Services;

public interface ICoffeeStationService
{
    IReadOnlyList<CoffeeStation> GetStations();
    IReadOnlyList<CoffeeStation> FilterStations(string? query);
}
