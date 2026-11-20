using System.Collections.ObjectModel;
using System.Windows.Input;
using MauiGoogleMapSample.Models;
using MauiGoogleMapSample.Services;
using Microsoft.Maui.Controls.Maps;
using Microsoft.Maui.Devices.Sensors;
using Microsoft.Maui.Maps;

namespace MauiGoogleMapSample.ViewModels;

public class CoffeeRoutesViewModel : BaseViewModel
{
    private readonly ICoffeeStationService _stationService;
    private readonly ICoffeeRouteService _routeService;

    private bool _showRoute = true;
    private bool _showDeliveryZone = true;
    private double _totalTourDistanceKm;
    private string _routeSummary = string.Empty;

    private readonly Command _toggleRouteCommand;
    private readonly Command _toggleDeliveryZoneCommand;
    private readonly Command _clearOverlaysCommand;

    public event Action? MapElementsChanged;

    public CoffeeRoutesViewModel(ICoffeeStationService stationService, ICoffeeRouteService routeService)
    {
        _stationService = stationService;
        _routeService = routeService;
        Title = "CoffeeMap — שלב 5: מסלולים וצורות";

        IReadOnlyList<CoffeeStation> stations = _stationService.GetStations();
        Stations = new ObservableCollection<CoffeeStation>(stations);
        _totalTourDistanceKm = _routeService.CalculateTotalTourDistanceKm(stations);

        _toggleRouteCommand = new Command(ExecuteToggleRoute);
        _toggleDeliveryZoneCommand = new Command(ExecuteToggleDeliveryZone);
        _clearOverlaysCommand = new Command(ExecuteClearOverlays, CanExecuteClearOverlays);

        UpdateRouteSummary();
    }

    public ObservableCollection<CoffeeStation> Stations { get; }

    public bool ShowRoute
    {
        get => _showRoute;
        set
        {
            if (_showRoute == value) return;
            _showRoute = value;
            OnPropertyChanged();
            _clearOverlaysCommand.ChangeCanExecute();
            UpdateRouteSummary();
            MapElementsChanged?.Invoke();
        }
    }

    public bool ShowDeliveryZone
    {
        get => _showDeliveryZone;
        set
        {
            if (_showDeliveryZone == value) return;
            _showDeliveryZone = value;
            OnPropertyChanged();
            _clearOverlaysCommand.ChangeCanExecute();
            UpdateRouteSummary();
            MapElementsChanged?.Invoke();
        }
    }

    public double TotalTourDistanceKm
    {
        get => _totalTourDistanceKm;
        set
        {
            if (Math.Abs(_totalTourDistanceKm - value) < 0.001) return;
            _totalTourDistanceKm = value;
            OnPropertyChanged();
        }
    }

    public string RouteSummary
    {
        get => _routeSummary;
        set
        {
            if (_routeSummary == value) return;
            _routeSummary = value;
            OnPropertyChanged();
        }
    }

    public ICommand ToggleRouteCommand => _toggleRouteCommand;
    public ICommand ToggleDeliveryZoneCommand => _toggleDeliveryZoneCommand;
    public ICommand ClearOverlaysCommand => _clearOverlaysCommand;

    public IReadOnlyList<MapElement> BuildActiveMapElements()
    {
        var elements = new List<MapElement>();

        if (ShowRoute && Stations.Count >= 2)
        {
            elements.Add(_routeService.BuildCoffeeTourPolyline(Stations));
        }

        if (ShowDeliveryZone && Stations.Count > 0)
        {
            elements.Add(_routeService.BuildDeliveryZoneCircle(Stations[0].Location, 800));
        }

        return elements;
    }

    public MapSpan GetInitialMapSpan()
    {
        Location center = Stations.Count > 0 ? Stations[0].Location : new Location(32.0636, 34.7731);
        return MapSpan.FromCenterAndRadius(center, Distance.FromKilometers(3.5));
    }

    private void ExecuteToggleRoute()
    {
        ShowRoute = !ShowRoute;
    }

    private void ExecuteToggleDeliveryZone()
    {
        ShowDeliveryZone = !ShowDeliveryZone;
    }

    private bool CanExecuteClearOverlays()
    {
        return ShowRoute || ShowDeliveryZone;
    }

    private void ExecuteClearOverlays()
    {
        ShowRoute = false;
        ShowDeliveryZone = false;
    }

    private void UpdateRouteSummary()
    {
        string routeState = ShowRoute ? "מסלול פעיל" : "מסלול מוסתר";
        string zoneState = ShowDeliveryZone ? "אזור משלוח פעיל (800 מ')" : "אזור משלוח מוסתר";
        RouteSummary = $"אורך סיור הקפה: {TotalTourDistanceKm:0.##} ק\"מ | {routeState} | {zoneState}";
    }
}
