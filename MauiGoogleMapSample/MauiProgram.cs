#if DEBUG
#if ANDROID || IOS || MACCATALYST || WINDOWS
using Microsoft.Maui.DevFlow.Agent;
#endif
#endif
using Microsoft.Extensions.Logging;
using MauiGoogleMapSample.Services;
using MauiGoogleMapSample.ViewModels;

namespace MauiGoogleMapSample;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .UseMauiMaps()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
            });

        // Dependency Injection registrations
        builder.Services.AddSingleton<IMapConfigurationValidator, MapConfigurationValidator>();
        builder.Services.AddTransient<SetupStatusViewModel>();
        builder.Services.AddTransient<MainPage>();

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
}
