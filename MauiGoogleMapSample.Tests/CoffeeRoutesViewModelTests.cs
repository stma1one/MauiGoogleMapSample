using MauiGoogleMapSample.Services;
using MauiGoogleMapSample.ViewModels;
using Microsoft.Maui.Controls.Maps;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class CoffeeRoutesViewModelTests
{
    [Fact]
    public void Constructor_StartsWithBothOverlaysActiveAndTwoMapElements()
    {
        // Arrange
        var vm = new CoffeeRoutesViewModel(new CoffeeStationService(), new CoffeeRouteService());

        // Act
        IReadOnlyList<MapElement> elements = vm.BuildActiveMapElements();

        // Assert
        Assert.True(vm.ShowRoute);
        Assert.True(vm.ShowDeliveryZone);
        Assert.Equal(2, elements.Count);
        Assert.Contains(elements, e => e is Polyline);
        Assert.Contains(elements, e => e is Circle);
        Assert.True(vm.ClearOverlaysCommand.CanExecute(null));
    }

    [Fact]
    public void ClearOverlaysCommand_RemovesAllElementsAndDisablesCommand()
    {
        // Arrange
        var vm = new CoffeeRoutesViewModel(new CoffeeStationService(), new CoffeeRouteService());

        // Act
        vm.ClearOverlaysCommand.Execute(null);
        IReadOnlyList<MapElement> elements = vm.BuildActiveMapElements();

        // Assert
        Assert.False(vm.ShowRoute);
        Assert.False(vm.ShowDeliveryZone);
        Assert.Empty(elements);
        Assert.False(vm.ClearOverlaysCommand.CanExecute(null));
    }

    [Fact]
    public void ToggleRouteCommand_TogglesPolylineAndRaisesMapElementsChanged()
    {
        // Arrange
        var vm = new CoffeeRoutesViewModel(new CoffeeStationService(), new CoffeeRouteService());
        int eventCount = 0;
        vm.MapElementsChanged += () => eventCount++;

        // Act
        vm.ToggleRouteCommand.Execute(null);
        IReadOnlyList<MapElement> elements = vm.BuildActiveMapElements();

        // Assert
        Assert.False(vm.ShowRoute);
        Assert.Single(elements);
        Assert.IsType<Circle>(elements[0]);
        Assert.Equal(1, eventCount);
    }
}
