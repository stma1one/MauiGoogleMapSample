using MauiGoogleMapSample.ViewModels;

namespace MauiGoogleMapSample;

public partial class MainPage : ContentPage
{
    public MainPage(SetupStatusViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
