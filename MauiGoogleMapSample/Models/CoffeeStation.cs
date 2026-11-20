using Microsoft.Maui.Devices.Sensors;

namespace MauiGoogleMapSample.Models;

public class CoffeeStation
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Specialty { get; set; } = string.Empty;
    public double Rating { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }

    public Location Location => new Location(Latitude, Longitude);
}
