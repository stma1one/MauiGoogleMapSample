using MauiGoogleMapSample.Models;
using MauiGoogleMapSample.Services;
using MauiGoogleMapSample.ViewModels;
using Microsoft.Maui.Devices.Sensors;
using Microsoft.Maui.Maps;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class UserLocationViewModelTests
{
    private sealed class FakeLocationService : ILocationService
    {
        private readonly LocationFetchResult _resultToReturn;
        private readonly bool _shouldThrow;
        private readonly LocationService _realCalculator = new();

        public FakeLocationService(LocationFetchResult resultToReturn, bool shouldThrow = false)
        {
            _resultToReturn = resultToReturn;
            _shouldThrow = shouldThrow;
        }

        public Task<LocationFetchResult> GetCurrentLocationAsync()
        {
            if (_shouldThrow)
            {
                throw new InvalidOperationException("Simulated GPS sensor error");
            }
            return Task.FromResult(_resultToReturn);
        }

        public double CalculateDistanceKm(Location from, Location to) =>
            _realCalculator.CalculateDistanceKm(from, to);

        public (CoffeeStation? Station, double DistanceKm) FindNearestStation(Location userLocation, IEnumerable<CoffeeStation> stations) =>
            _realCalculator.FindNearestStation(userLocation, stations);
    }

    [Fact]
    public async Task ExecuteLocateMeAsync_WhenPermissionGranted_SetsShowingUserAndFindsNearestStation()
    {
        // Arrange — User standing right next to Sheinkin (32.0694, 34.7721)
        var userLocation = new Location(32.0694, 34.7721);
        var fakeService = new FakeLocationService(
            new LocationFetchResult(true, true, userLocation, "מיקום נוכחי אותר"));
        var vm = new UserLocationViewModel(fakeService, new CoffeeStationService());
        MapSpan? requestedSpan = null;
        vm.MoveToRegionRequested += span => requestedSpan = span;

        // Act
        await vm.ExecuteLocateMeAsync();

        // Assert
        Assert.False(vm.IsLoading);
        Assert.True(vm.IsShowingUser);
        Assert.Equal(userLocation, vm.CurrentUserLocation);
        Assert.Contains("קליית שנקין", vm.NearestStationSummary);
        Assert.NotNull(requestedSpan);
    }

    [Fact]
    public async Task ExecuteLocateMeAsync_WhenPermissionDenied_DisablesShowingUserAndReportsError()
    {
        // Arrange
        var fakeService = new FakeLocationService(
            new LocationFetchResult(false, false, null, "הרשאת מיקום נדחתה"));
        var vm = new UserLocationViewModel(fakeService, new CoffeeStationService());

        // Act
        await vm.ExecuteLocateMeAsync();

        // Assert
        Assert.False(vm.IsLoading);
        Assert.False(vm.IsShowingUser);
        Assert.Contains("נדחתה", vm.LocationStatus);
    }

    [Fact]
    public async Task ExecuteLocateMeAsync_WhenServiceThrows_RecoversGracefullyAndResetsIsLoading()
    {
        // Arrange
        var fakeService = new FakeLocationService(
            new LocationFetchResult(false, false, null, string.Empty),
            shouldThrow: true);
        var vm = new UserLocationViewModel(fakeService, new CoffeeStationService());

        // Act
        await vm.ExecuteLocateMeAsync();

        // Assert
        Assert.False(vm.IsLoading);
        Assert.False(vm.IsShowingUser);
        Assert.Contains("שגיאה", vm.LocationStatus);
    }
}
