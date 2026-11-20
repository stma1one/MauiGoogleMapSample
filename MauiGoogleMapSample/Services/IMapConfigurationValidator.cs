namespace MauiGoogleMapSample.Services;

public record MapConfigCheckResult(bool IsValid, string StatusTitle, string Details);

public interface IMapConfigurationValidator
{
    string PlaceholderKey { get; }
    MapConfigCheckResult ValidateApiKey(string? apiKey);
}
