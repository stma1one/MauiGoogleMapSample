namespace MauiGoogleMapSample.Services;

public interface ISecureKeyStorageService
{
    Task SaveApiKeyAsync(string apiKey);
    Task<string?> GetApiKeyAsync();
    void ClearApiKey();
}
