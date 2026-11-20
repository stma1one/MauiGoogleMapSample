#if DEBUG
#if ANDROID || IOS || MACCATALYST || WINDOWS
using Microsoft.Maui.DevFlow.Agent;
#endif
#endif
using Microsoft.Extensions.Logging;
using MauiGoogleMapSample.Services;
using MauiGoogleMapSample.ViewModels;
using MauiGoogleMapSample.Views;

namespace MauiGoogleMapSample;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .UseMauiMaps()
            .RegisterServices()
            .RegisterViewModels()
            .RegisterViews()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
            });

#if DEBUG
        builder.Logging.AddDebug();
#endif

#if DEBUG
#if ANDROID || IOS || MACCATALYST || WINDOWS
        builder.AddMauiDevFlowAgent();
#endif
#endif
        return builder.Build();
    }

    private static MauiAppBuilder RegisterServices(this MauiAppBuilder builder)
    {
        builder.Services.AddSingleton<IMapConfigurationValidator, MapConfigurationValidator>();
        builder.Services.AddSingleton<ICoffeeRegionService, CoffeeRegionService>();
        builder.Services.AddSingleton<ICoffeeStationService, CoffeeStationService>();
        builder.Services.AddSingleton<ILocationService, LocationService>();
        return builder;
    }

    private static MauiAppBuilder RegisterViewModels(this MauiAppBuilder builder)
    {
        builder.Services.AddTransient<SetupStatusViewModel>();
        builder.Services.AddTransient<MapDisplayViewModel>();
        builder.Services.AddTransient<CoffeePinsViewModel>();
        builder.Services.AddTransient<UserLocationViewModel>();
        return builder;
    }

    private static MauiAppBuilder RegisterViews(this MauiAppBuilder builder)
    {
        builder.Services.AddTransient<MainPage>();
        builder.Services.AddTransient<MapDisplayPage>();
        builder.Services.AddTransient<CoffeePinsPage>();
        builder.Services.AddTransient<UserLocationPage>();
        return builder;
    }
}
