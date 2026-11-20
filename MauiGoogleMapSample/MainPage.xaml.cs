using MauiGoogleMapSample.ViewModels;

namespace MauiGoogleMapSample;

public partial class MainPage : ContentPage
{
    private readonly SetupStatusViewModel _viewModel;

    public MainPage(SetupStatusViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        BindingContext = _viewModel;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await _viewModel.LoadSavedKeyAsync();
    }
}
