using MauiGoogleMapSample.Models;

namespace MauiGoogleMapSample.Services;

public class CoffeeStationService : ICoffeeStationService
{
    private readonly List<CoffeeStation> _stations = new()
    {
        new CoffeeStation
        {
            Id = "tlv-1",
            Name = "קפה רוטשילד 45",
            Address = "שדרות רוטשילד 45, תל אביב",
            Specialty = "אספרסו וקולד ברו",
            Rating = 4.8,
            Latitude = 32.0636,
            Longitude = 34.7731
        },
        new CoffeeStation
        {
            Id = "tlv-2",
            Name = "קליית שנקין",
            Address = "רחוב שנקין 22, תל אביב",
            Specialty = "פילטר וקלייה מקומית",
            Rating = 4.6,
            Latitude = 32.0695,
            Longitude = 34.7720
        },
        new CoffeeStation
        {
            Id = "tlv-3",
            Name = "תחנת הקפה נווה צדק",
            Address = "רחוב שבזי 30, תל אביב",
            Specialty = "מאצ'ה וקפוצ'ינו שיבולת שועל",
            Rating = 4.4,
            Latitude = 32.0604,
            Longitude = 34.7652
        },
        new CoffeeStation
        {
            Id = "tlv-4",
            Name = "בוקר בנמל",
            Address = "האנגר 12, נמל תל אביב",
            Specialty = "אספרסו קלאסי ומאפים",
            Rating = 4.2,
            Latitude = 32.0965,
            Longitude = 34.7745
        }
    };

    public IReadOnlyList<CoffeeStation> GetStations()
    {
        return _stations.AsReadOnly();
    }

    public IReadOnlyList<CoffeeStation> FilterStations(string? query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return _stations.AsReadOnly();
        }

        string trimmed = query.Trim();
        return _stations
            .Where(s =>
                s.Name.Contains(trimmed, StringComparison.OrdinalIgnoreCase) ||
                s.Address.Contains(trimmed, StringComparison.OrdinalIgnoreCase) ||
                s.Specialty.Contains(trimmed, StringComparison.OrdinalIgnoreCase))
            .ToList();
    }
}
