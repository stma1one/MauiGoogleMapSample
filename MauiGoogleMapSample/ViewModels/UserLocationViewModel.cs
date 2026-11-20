using System.Collections.ObjectModel;
using System.Windows.Input;
using MauiGoogleMapSample.Models;
using MauiGoogleMapSample.Services;
using Microsoft.Maui.Devices.Sensors;
using Microsoft.Maui.Maps;

namespace MauiGoogleMapSample.ViewModels;

public class UserLocationViewModel : BaseViewModel
{
    private readonly ILocationService _locationService;
    private readonly ICoffeeStationService _stationService;

    private bool _isShowingUser;
    private Location? _currentUserLocation;
    private string _locationStatus = "לחצו על הכפתור כדי לאתר את המיקום שלכם ולמצוא את תחנת הקפה הקרובה";
    private string _nearestStationSummary = "עדיין לא חושב מרחק לתחנת קפה קרובה";
    private readonly Command _locateMeCommand;

    public event Action<MapSpan>? MoveToRegionRequested;

    public UserLocationViewModel(ILocationService locationService, ICoffeeStationService stationService)
    {
        _locationService = locationService;
        _stationService = stationService;
        Title = "CoffeeMap — שלב 4: מיקום GPS";

        Stations = new ObservableCollection<CoffeeStation>(_stationService.GetStations());
        _locateMeCommand = new Command(async () => await ExecuteLocateMeAsync(), CanExecuteLocateMe);
    }

    public ObservableCollection<CoffeeStation> Stations { get; }

    public bool IsShowingUser
    {
        get => _isShowingUser;
        set
        {
            if (_isShowingUser == value) return;
            _isShowingUser = value;
            OnPropertyChanged();
        }
    }

    public Location? CurrentUserLocation
    {
        get => _currentUserLocation;
        set
        {
            if (_currentUserLocation == value) return;
            _currentUserLocation = value;
            OnPropertyChanged();
        }
    }

    public string LocationStatus
    {
        get => _locationStatus;
        set
        {
            if (_locationStatus == value) return;
            _locationStatus = value;
            OnPropertyChanged();
        }
    }

    public string NearestStationSummary
    {
        get => _nearestStationSummary;
        set
        {
            if (_nearestStationSummary == value) return;
            _nearestStationSummary = value;
            OnPropertyChanged();
        }
    }

    public ICommand LocateMeCommand => _locateMeCommand;

    private bool CanExecuteLocateMe()
    {
        return !IsLoading;
    }

    public async Task ExecuteLocateMeAsync()
    {
        if (IsLoading) return;

        IsLoading = true;
        _locateMeCommand.ChangeCanExecute();

        try
        {
            LocationStatus = "מבקש הרשאת מיקום ומאתר GPS...";
            LocationFetchResult result = await _locationService.GetCurrentLocationAsync();

            if (!result.IsSuccess || result.Location is null)
            {
                IsShowingUser = false;
                LocationStatus = result.Message;
                NearestStationSummary = "לא ניתן לחשב מרחק ללא מיקום נוכחי.";
                return;
            }

            IsShowingUser = result.PermissionGranted;
            CurrentUserLocation = result.Location;
            LocationStatus = result.Message;

            (CoffeeStation? nearest, double distanceKm) = _locationService.FindNearestStation(result.Location, Stations);
            NearestStationSummary = nearest is not null
                ? $"☕ התחנה הקרובה ביותר: {nearest.Name} (במרחק {distanceKm:0.##} ק\"מ)"
                : "לא נמצאו תחנות קפה במאגר.";

            MapSpan span = MapSpan.FromCenterAndRadius(result.Location, Distance.FromKilometers(2.0));
            MoveToRegionRequested?.Invoke(span);
        }
        catch (Exception ex)
        {
            IsShowingUser = false;
            LocationStatus = $"שגיאה בלתי צפויה באיתור מיקום: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
            _locateMeCommand.ChangeCanExecute();
        }
    }
}
