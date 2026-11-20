using MauiGoogleMapSample.Services;
using MauiGoogleMapSample.ViewModels;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class CoffeePinsViewModelTests
{
    [Fact]
    public void Constructor_LoadsAllStationsAndDisablesClearFilter()
    {
        // Arrange
        var service = new CoffeeStationService();

        // Act
        var vm = new CoffeePinsViewModel(service);

        // Assert
        Assert.Equal(4, vm.Stations.Count);
        Assert.False(vm.ClearFilterCommand.CanExecute(null));
    }

    [Fact]
    public void FilterCommand_FiltersStationsAndClearFilterRestoresAll()
    {
        // Arrange
        var vm = new CoffeePinsViewModel(new CoffeeStationService());

        // Act — Filter
        vm.SearchQuery = "שנקין";
        vm.FilterCommand.Execute(null);

        // Assert — Filtered
        Assert.Single(vm.Stations);
        Assert.True(vm.ClearFilterCommand.CanExecute(null));

        // Act — Clear
        vm.ClearFilterCommand.Execute(null);

        // Assert — Restored
        Assert.Equal(4, vm.Stations.Count);
        Assert.False(vm.ClearFilterCommand.CanExecute(null));
    }

    [Fact]
    public void SelectStationByNameCommand_UpdatesSelectedStationAndBanner()
    {
        // Arrange
        var vm = new CoffeePinsViewModel(new CoffeeStationService());

        // Act
        vm.SelectStationByNameCommand.Execute("קפה רוטשילד 45");

        // Assert
        Assert.NotNull(vm.SelectedStation);
        Assert.Equal("קפה רוטשילד 45", vm.SelectedStation.Name);
        Assert.Contains("4.8", vm.SelectedStationBanner);
    }
}
