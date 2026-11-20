using MauiGoogleMapSample.ViewModels;
using Microsoft.Maui.Controls.Maps;

namespace MauiGoogleMapSample.Views;

public partial class CoffeeRoutesPage : ContentPage
{
    private readonly CoffeeRoutesViewModel _viewModel;

    public CoffeeRoutesPage(CoffeeRoutesViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        BindingContext = _viewModel;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        _viewModel.MapElementsChanged += RefreshMapElements;
        Dispatcher.Dispatch(() =>
        {
            try
            {
                RoutesMapControl?.MoveToRegion(_viewModel.GetInitialMapSpan());
                RefreshMapElements();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[CoffeeMap] Route map init skipped: {ex.Message}");
            }
        });
    }

    protected override void OnDisappearing()
    {
        _viewModel.MapElementsChanged -= RefreshMapElements;
        base.OnDisappearing();
    }

    private void RefreshMapElements()
    {
        Dispatcher.Dispatch(() =>
        {
            try
            {
                if (RoutesMapControl is null) return;
                RoutesMapControl.MapElements.Clear();
                foreach (MapElement element in _viewModel.BuildActiveMapElements())
                {
                    RoutesMapControl.MapElements.Add(element);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[CoffeeMap] RefreshMapElements skipped: {ex.Message}");
            }
        });
    }
}
