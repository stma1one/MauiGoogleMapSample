using System.Collections.ObjectModel;
using System.Windows.Input;
using MauiGoogleMapSample.Models;
using MauiGoogleMapSample.Services;
using Microsoft.Maui.Maps;

namespace MauiGoogleMapSample.ViewModels;

public class MapDisplayViewModel : BaseViewModel
{
    private const double MinZoomRadiusKm = 0.25;
    private const double MaxZoomRadiusKm = 20.0;

    private readonly ICoffeeRegionService _regionService;
    private readonly ISecureKeyStorageService _secureStorage;
    private MapType _selectedMapType = MapType.Street;
    private CoffeeRegion _selectedRegion;
    private double _zoomRadiusKm;
    private string _regionSummary = string.Empty;
    private string _apiKeyStatusBadge = "בודק מפתח API באחסון המוצפן...";

    private readonly Command<string> _setMapTypeCommand;
    private readonly Command<CoffeeRegion> _selectRegionCommand;
    private readonly Command _zoomInCommand;
    private readonly Command _zoomOutCommand;

    public event Action<MapSpan>? MoveToRegionRequested;

    public MapDisplayViewModel(
        ICoffeeRegionService regionService,
        ISecureKeyStorageService secureStorage)
    {
        _regionService = regionService;
        _secureStorage = secureStorage;
        Title = "CoffeeMap — שלב 2: תצוגת מפה";

        IReadOnlyList<CoffeeRegion> defaultRegions = _regionService.GetDefaultRegions();
        Regions = new ObservableCollection<CoffeeRegion>(defaultRegions);
        _selectedRegion = Regions[0];
        _zoomRadiusKm = _selectedRegion.DefaultRadiusKm;

        _setMapTypeCommand = new Command<string>(ExecuteSetMapType);
        _selectRegionCommand = new Command<CoffeeRegion>(ExecuteSelectRegion, CanExecuteSelectRegion);
        _zoomInCommand = new Command(ExecuteZoomIn, CanExecuteZoomIn);
        _zoomOutCommand = new Command(ExecuteZoomOut, CanExecuteZoomOut);

        UpdateRegionSummary();
    }

    public ObservableCollection<CoffeeRegion> Regions { get; }

    public MapType SelectedMapType
    {
        get => _selectedMapType;
        set
        {
            if (_selectedMapType == value) return;
            _selectedMapType = value;
            OnPropertyChanged();
            UpdateRegionSummary();
        }
    }

    public CoffeeRegion SelectedRegion
    {
        get => _selectedRegion;
        set
        {
            if (_selectedRegion == value || value is null) return;
            _selectedRegion = value;
            OnPropertyChanged();
            UpdateRegionSummary();
        }
    }

    public double ZoomRadiusKm
    {
        get => _zoomRadiusKm;
        set
        {
            if (Math.Abs(_zoomRadiusKm - value) < 0.001) return;
            _zoomRadiusKm = value;
            OnPropertyChanged();
            _zoomInCommand.ChangeCanExecute();
            _zoomOutCommand.ChangeCanExecute();
            UpdateRegionSummary();
        }
    }

    public string RegionSummary
    {
        get => _regionSummary;
        set
        {
            if (_regionSummary == value) return;
            _regionSummary = value;
            OnPropertyChanged();
        }
    }

    public string ApiKeyStatusBadge
    {
        get => _apiKeyStatusBadge;
        set
        {
            if (_apiKeyStatusBadge == value) return;
            _apiKeyStatusBadge = value;
            OnPropertyChanged();
        }
    }

    public ICommand SetMapTypeCommand => _setMapTypeCommand;
    public ICommand SelectRegionCommand => _selectRegionCommand;
    public ICommand ZoomInCommand => _zoomInCommand;
    public ICommand ZoomOutCommand => _zoomOutCommand;

    public async Task LoadStoredKeyStatusAsync()
    {
        try
        {
            string? savedKey = await _secureStorage.GetApiKeyAsync();
            if (!string.IsNullOrWhiteSpace(savedKey))
            {
                string masked = savedKey.Length >= 8 ? $"{savedKey[..4]}••••{savedKey[^4..]}" : "••••";
                ApiKeyStatusBadge = $"🔐 מפתח API נשלף מ-SecureStorage ({masked})";
            }
            else
            {
                ApiKeyStatusBadge = "⚠️ לא נשמר מפתח ב-SecureStorage (ניתן להזין בשלב 1)";
            }
        }
        catch
        {
            ApiKeyStatusBadge = "⚠️ לא ניתן לקרוא מ-SecureStorage";
        }
    }

    public MapSpan GetCurrentMapSpan()
    {
        return _regionService.BuildMapSpan(SelectedRegion, ZoomRadiusKm);
    }

    private void ExecuteSetMapType(string? mapTypeName)
    {
        if (string.IsNullOrWhiteSpace(mapTypeName)) return;

        if (Enum.TryParse<MapType>(mapTypeName, ignoreCase: true, out MapType parsed))
        {
            SelectedMapType = parsed;
        }
    }

    private bool CanExecuteSelectRegion(CoffeeRegion? region)
    {
        return region is not null;
    }

    private void ExecuteSelectRegion(CoffeeRegion? region)
    {
        if (region is null) return;

        SelectedRegion = region;
        ZoomRadiusKm = region.DefaultRadiusKm;
        RequestMapMove();
    }

    private bool CanExecuteZoomIn()
    {
        return ZoomRadiusKm > MinZoomRadiusKm;
    }

    private void ExecuteZoomIn()
    {
        ZoomRadiusKm = Math.Max(MinZoomRadiusKm, Math.Round(ZoomRadiusKm / 1.5, 2));
        RequestMapMove();
    }

    private bool CanExecuteZoomOut()
    {
        return ZoomRadiusKm < MaxZoomRadiusKm;
    }

    private void ExecuteZoomOut()
    {
        ZoomRadiusKm = Math.Min(MaxZoomRadiusKm, Math.Round(ZoomRadiusKm * 1.5, 2));
        RequestMapMove();
    }

    private void RequestMapMove()
    {
        MapSpan span = GetCurrentMapSpan();
        MoveToRegionRequested?.Invoke(span);
    }

    private void UpdateRegionSummary()
    {
        string typeHebrew = SelectedMapType switch
        {
            MapType.Street => "רחובות (Street)",
            MapType.Satellite => "לוויין (Satellite)",
            MapType.Hybrid => "משולב (Hybrid)",
            _ => SelectedMapType.ToString()
        };

        RegionSummary = $"{SelectedRegion.Name} | תצוגה: {typeHebrew} | רדיוס: {ZoomRadiusKm:0.##} ק\"מ";
    }
}
