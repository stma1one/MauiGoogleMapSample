namespace MauiGoogleMapSample.Models;

public class CoffeeRegion
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double DefaultRadiusKm { get; set; } = 1.5;
}
