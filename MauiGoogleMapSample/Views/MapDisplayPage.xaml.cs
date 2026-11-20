using MauiGoogleMapSample.ViewModels;
using Microsoft.Maui.Maps;

namespace MauiGoogleMapSample.Views;

public partial class MapDisplayPage : ContentPage
{
    private readonly MapDisplayViewModel _viewModel;

    public MapDisplayPage(MapDisplayViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        BindingContext = _viewModel;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        _viewModel.MoveToRegionRequested += OnMoveToRegionRequested;
        CoffeeMapControl.MoveToRegion(_viewModel.GetCurrentMapSpan());
    }

    protected override void OnDisappearing()
    {
        _viewModel.MoveToRegionRequested -= OnMoveToRegionRequested;
        base.OnDisappearing();
    }

    private void OnMoveToRegionRequested(MapSpan span)
    {
        CoffeeMapControl.MoveToRegion(span);
    }
}
