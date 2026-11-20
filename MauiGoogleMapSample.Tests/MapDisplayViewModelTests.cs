using MauiGoogleMapSample.Models;
using MauiGoogleMapSample.Services;
using MauiGoogleMapSample.ViewModels;
using Microsoft.Maui.Maps;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class MapDisplayViewModelTests
{
    private sealed class FakeSecureKeyStorageService : ISecureKeyStorageService
    {
        private string? _key;
        public FakeSecureKeyStorageService(string? initialKey = null) => _key = initialKey;
        public Task SaveApiKeyAsync(string apiKey) { _key = apiKey; return Task.CompletedTask; }
        public Task<string?> GetApiKeyAsync() => Task.FromResult(_key);
        public void ClearApiKey() => _key = null;
    }

    [Fact]
    public void Constructor_InitializesWithStreetMapAndFirstRegion()
    {
        // Arrange & Act
        var vm = new MapDisplayViewModel(new CoffeeRegionService(), new FakeSecureKeyStorageService());

        // Assert
        Assert.Equal(MapType.Street, vm.SelectedMapType);
        Assert.Equal(3, vm.Regions.Count);
        Assert.Equal(vm.Regions[0], vm.SelectedRegion);
        Assert.Contains("רחובות", vm.RegionSummary);
    }

    [Fact]
    public void SetMapTypeCommand_SwitchesToSatelliteAndHybrid()
    {
        // Arrange
        var vm = new MapDisplayViewModel(new CoffeeRegionService(), new FakeSecureKeyStorageService());

        // Act
        vm.SetMapTypeCommand.Execute("Satellite");

        // Assert
        Assert.Equal(MapType.Satellite, vm.SelectedMapType);
        Assert.Contains("לוויין", vm.RegionSummary);

        // Act 2
        vm.SetMapTypeCommand.Execute("Hybrid");

        // Assert 2
        Assert.Equal(MapType.Hybrid, vm.SelectedMapType);
        Assert.Contains("משולב", vm.RegionSummary);
    }

    [Fact]
    public void SelectRegionCommand_UpdatesRegionAndRaisesMoveToRegionEvent()
    {
        // Arrange
        var vm = new MapDisplayViewModel(new CoffeeRegionService(), new FakeSecureKeyStorageService());
        CoffeeRegion jerusalem = vm.Regions[1];
        MapSpan? capturedSpan = null;
        vm.MoveToRegionRequested += span => capturedSpan = span;

        // Act
        vm.SelectRegionCommand.Execute(jerusalem);

        // Assert
        Assert.Equal(jerusalem, vm.SelectedRegion);
        Assert.NotNull(capturedSpan);
        Assert.Equal(jerusalem.Latitude, capturedSpan.Center.Latitude, 4);
    }

    [Fact]
    public void ZoomInAndOutCommands_UpdateRadiusAndRespectCanExecuteBounds()
    {
        // Arrange
        var vm = new MapDisplayViewModel(new CoffeeRegionService(), new FakeSecureKeyStorageService());
        double initialRadius = vm.ZoomRadiusKm;

        // Act — Zoom In
        vm.ZoomInCommand.Execute(null);

        // Assert — Radius decreased
        Assert.True(vm.ZoomRadiusKm < initialRadius);

        // Act — Force min bound
        vm.ZoomRadiusKm = 0.25;

        // Assert — Cannot zoom in further
        Assert.False(vm.ZoomInCommand.CanExecute(null));
        Assert.True(vm.ZoomOutCommand.CanExecute(null));
    }

    [Fact]
    public async Task LoadStoredKeyStatusAsync_WhenKeyStored_DisplaysMaskedKeyFromSecureStorage()
    {
        // Arrange
        var fakeStorage = new FakeSecureKeyStorageService("AIzaSyFakeExampleKeyForUnitTests9999");
        var vm = new MapDisplayViewModel(new CoffeeRegionService(), fakeStorage);

        // Act
        await vm.LoadStoredKeyStatusAsync();

        // Assert
        Assert.Contains("SecureStorage", vm.ApiKeyStatusBadge);
        Assert.Contains("AIza", vm.ApiKeyStatusBadge);
        Assert.Contains("9999", vm.ApiKeyStatusBadge);
        Assert.DoesNotContain("FakeExampleKey", vm.ApiKeyStatusBadge);
    }
}
