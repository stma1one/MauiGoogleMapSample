using Microsoft.Maui.Storage;

namespace MauiGoogleMapSample.Services;

public class SecureKeyStorageService : ISecureKeyStorageService
{
    private const string GoogleMapsApiKeyStorageKey = "coffeemap_google_maps_api_key";

    public async Task SaveApiKeyAsync(string apiKey)
    {
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new ArgumentException("API key cannot be empty.", nameof(apiKey));
        }

        await SecureStorage.Default.SetAsync(GoogleMapsApiKeyStorageKey, apiKey.Trim());
    }

    public async Task<string?> GetApiKeyAsync()
    {
        return await SecureStorage.Default.GetAsync(GoogleMapsApiKeyStorageKey);
    }

    public void ClearApiKey()
    {
        SecureStorage.Default.Remove(GoogleMapsApiKeyStorageKey);
    }
}
