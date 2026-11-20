using MauiGoogleMapSample.ViewModels;
using Microsoft.Maui.Devices.Sensors;
using Microsoft.Maui.Maps;

namespace MauiGoogleMapSample.Views;

public partial class UserLocationPage : ContentPage
{
    private readonly UserLocationViewModel _viewModel;

    public UserLocationPage(UserLocationViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        BindingContext = _viewModel;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        _viewModel.MoveToRegionRequested += OnMoveToRegionRequested;
        Dispatcher.Dispatch(() => SafeMoveToRegion(MapSpan.FromCenterAndRadius(new Location(32.0636, 34.7731), Distance.FromKilometers(3.0))));
    }

    protected override void OnDisappearing()
    {
        _viewModel.MoveToRegionRequested -= OnMoveToRegionRequested;
        base.OnDisappearing();
    }

    private void OnMoveToRegionRequested(MapSpan span)
    {
        Dispatcher.Dispatch(() => SafeMoveToRegion(span));
    }

    private void SafeMoveToRegion(MapSpan span)
    {
        try
        {
            GpsMapControl?.MoveToRegion(span);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[CoffeeMap] MoveToRegion skipped: {ex.Message}");
        }
    }
}
