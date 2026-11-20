#if DEBUG
#if ANDROID || IOS || MACCATALYST || WINDOWS
using Microsoft.Maui.DevFlow.Agent;
#endif
#endif
﻿using Microsoft.Extensions.Logging;

namespace MauiGoogleMapSample
{
	public static class MauiProgram
	{
		public static MauiApp CreateMauiApp()
		{
			var builder = MauiApp.CreateBuilder();
			builder
				.UseMauiApp<App>()
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
	}
}
