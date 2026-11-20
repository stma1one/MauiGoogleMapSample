using MauiGoogleMapSample.Models;
using Microsoft.Maui.Maps;

namespace MauiGoogleMapSample.Services;

public interface ICoffeeRegionService
{
    IReadOnlyList<CoffeeRegion> GetDefaultRegions();
    MapSpan BuildMapSpan(CoffeeRegion region, double? overrideRadiusKm = null);
}
