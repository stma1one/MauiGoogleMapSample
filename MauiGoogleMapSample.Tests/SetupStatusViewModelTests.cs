using MauiGoogleMapSample.Services;
using MauiGoogleMapSample.ViewModels;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class SetupStatusViewModelTests
{
    private sealed class FakeSecureKeyStorageService : ISecureKeyStorageService
    {
        public string? StoredKey { get; private set; }

        public Task SaveApiKeyAsync(string apiKey)
        {
            StoredKey = apiKey;
            return Task.CompletedTask;
        }

        public Task<string?> GetApiKeyAsync()
        {
            return Task.FromResult(StoredKey);
        }

        public void ClearApiKey()
        {
            StoredKey = null;
        }
    }

    [Fact]
    public void Constructor_InitializesWithPlaceholderAndDisablesSaveCommand()
    {
        // Arrange
        var validator = new MapConfigurationValidator();
        var storage = new FakeSecureKeyStorageService();

        // Act
        var vm = new SetupStatusViewModel(validator, storage);

        // Assert
        Assert.Equal(validator.PlaceholderKey, vm.ApiKeyInput);
        Assert.False(vm.IsConfigured);
        Assert.False(vm.SaveKeyCommand.CanExecute(null));
    }

    [Fact]
    public void ValidateKeyCommand_WhenApiKeyEmpty_CannotExecute()
    {
        // Arrange
        var vm = new SetupStatusViewModel(new MapConfigurationValidator(), new FakeSecureKeyStorageService());

        // Act
        vm.ApiKeyInput = "";

        // Assert
        Assert.False(vm.ValidateKeyCommand.CanExecute(null));
        Assert.False(vm.SaveKeyCommand.CanExecute(null));
    }

    [Fact]
    public async Task ExecuteSaveKeyAsync_WhenValidKey_SavesToSecureStorageAndCanBeLoadedBack()
    {
        // Arrange
        var storage = new FakeSecureKeyStorageService();
        var vm = new SetupStatusViewModel(new MapConfigurationValidator(), storage);
        const string validKey = "AIzaSyFakeExampleKeyForUnitTests123456";

        // Act
        vm.ApiKeyInput = validKey;
        Assert.True(vm.SaveKeyCommand.CanExecute(null));
        await vm.ExecuteSaveKeyAsync();

        // Assert
        Assert.Equal(validKey, storage.StoredKey);
        Assert.True(vm.IsConfigured);
        Assert.Contains("SecureStorage", vm.StorageStatus);

        // Act 2 — Simulate reopening screen
        var vmReloaded = new SetupStatusViewModel(new MapConfigurationValidator(), storage);
        await vmReloaded.LoadSavedKeyAsync();

        // Assert 2
        Assert.Equal(validKey, vmReloaded.ApiKeyInput);
        Assert.True(vmReloaded.IsConfigured);
    }

    [Fact]
    public async Task ClearSavedKeyCommand_ClearsSecureStorageAndRestoresPlaceholder()
    {
        // Arrange
        var validator = new MapConfigurationValidator();
        var storage = new FakeSecureKeyStorageService();
        var vm = new SetupStatusViewModel(validator, storage);
        vm.ApiKeyInput = "AIzaSyFakeExampleKeyForUnitTests123456";
        await vm.ExecuteSaveKeyAsync();

        // Act
        vm.ClearSavedKeyCommand.Execute(null);

        // Assert
        Assert.Null(storage.StoredKey);
        Assert.Equal(validator.PlaceholderKey, vm.ApiKeyInput);
        Assert.False(vm.IsConfigured);
    }
}
