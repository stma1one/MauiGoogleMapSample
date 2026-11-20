using MauiGoogleMapSample.ViewModels;
using Microsoft.Maui.Controls.Maps;

namespace MauiGoogleMapSample.Views;

public partial class CoffeePinsPage : ContentPage
{
    private readonly CoffeePinsViewModel _viewModel;

    public CoffeePinsPage(CoffeePinsViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        BindingContext = _viewModel;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        PinsMapControl.MoveToRegion(_viewModel.GetInitialMapSpan());
    }

    private void OnPinMarkerClicked(object? sender, PinClickedEventArgs e)
    {
        if (sender is Pin pin)
        {
            _viewModel.SelectStationByNameCommand.Execute(pin.Label);
        }
    }

    private async void OnPinInfoWindowClicked(object? sender, PinClickedEventArgs e)
    {
        if (sender is Pin pin)
        {
            _viewModel.SelectStationByNameCommand.Execute(pin.Label);
            await DisplayAlertAsync(
                pin.Label,
                $"כתובת: {pin.Address}\n{_viewModel.SelectedStationBanner}",
                "סגור");
        }
    }
}
