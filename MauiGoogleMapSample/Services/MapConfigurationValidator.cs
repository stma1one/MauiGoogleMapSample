namespace MauiGoogleMapSample.Services;

public class MapConfigurationValidator : IMapConfigurationValidator
{
    public string PlaceholderKey => "YOUR_GOOGLE_MAPS_API_KEY_HERE";

    public MapConfigCheckResult ValidateApiKey(string? apiKey)
    {
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            return new MapConfigCheckResult(
                false,
                "מפתח API חסר",
                "לא הוזן מפתח Google Maps API. יש להזין מפתח תקין בקובץ AndroidManifest.xml.");
        }

        string trimmed = apiKey.Trim();

        if (string.Equals(trimmed, PlaceholderKey, StringComparison.OrdinalIgnoreCase))
        {
            return new MapConfigCheckResult(
                false,
                "מוגדר מפתח Placeholder",
                "הפרויקט משתמש כרגע במפתח הדגמה (Placeholder). כדי להציג מפת אמת באנדרואיד, יש להחליפו במפתח מ-Google Cloud Console.");
        }

        if (trimmed.Length < 20)
        {
            return new MapConfigCheckResult(
                false,
                "פורמט מפתח קצר מדי",
                "מפתח Google Maps API תקין ארוך מ-20 תווים (ובדרך כלל מתחיל ב-AIza).");
        }

        return new MapConfigCheckResult(
            true,
            "פורמט המפתח תקין",
            "המפתח עבר בדיקת תקינות בסיסית ומוכן לשימוש בהגדרות AndroidManifest.xml.");
    }
}
