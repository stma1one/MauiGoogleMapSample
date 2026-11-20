using System.Collections.ObjectModel;
using System.Windows.Input;
using MauiGoogleMapSample.Models;
using MauiGoogleMapSample.Services;
using Microsoft.Maui.Devices.Sensors;
using Microsoft.Maui.Maps;

namespace MauiGoogleMapSample.ViewModels;

public class CoffeePinsViewModel : BaseViewModel
{
    private readonly ICoffeeStationService _stationService;
    private string _searchQuery = string.Empty;
    private CoffeeStation? _selectedStation;
    private string _selectedStationBanner = "לחצו על סיכה במפה כדי לראות פרטי תחנת קפה";

    private readonly Command _filterCommand;
    private readonly Command _clearFilterCommand;
    private readonly Command<string> _selectStationByNameCommand;

    public CoffeePinsViewModel(ICoffeeStationService stationService)
    {
        _stationService = stationService;
        Title = "CoffeeMap — שלב 3: סיכות (Pins)";

        Stations = new ObservableCollection<CoffeeStation>(_stationService.GetStations());

        _filterCommand = new Command(ExecuteFilter);
        _clearFilterCommand = new Command(ExecuteClearFilter, CanExecuteClearFilter);
        _selectStationByNameCommand = new Command<string>(ExecuteSelectStationByName);
    }

    public ObservableCollection<CoffeeStation> Stations { get; }

    public string SearchQuery
    {
        get => _searchQuery;
        set
        {
            if (_searchQuery == value) return;
            _searchQuery = value;
            OnPropertyChanged();
            _clearFilterCommand.ChangeCanExecute();
        }
    }

    public CoffeeStation? SelectedStation
    {
        get => _selectedStation;
        set
        {
            if (_selectedStation == value) return;
            _selectedStation = value;
            OnPropertyChanged();
            UpdateBanner();
        }
    }

    public string SelectedStationBanner
    {
        get => _selectedStationBanner;
        set
        {
            if (_selectedStationBanner == value) return;
            _selectedStationBanner = value;
            OnPropertyChanged();
        }
    }

    public ICommand FilterCommand => _filterCommand;
    public ICommand ClearFilterCommand => _clearFilterCommand;
    public ICommand SelectStationByNameCommand => _selectStationByNameCommand;

    public MapSpan GetInitialMapSpan()
    {
        CoffeeStation? first = Stations.FirstOrDefault();
        Location center = first is not null ? first.Location : new Location(32.0636, 34.7731);
        return MapSpan.FromCenterAndRadius(center, Distance.FromKilometers(3.0));
    }

    private void ExecuteFilter()
    {
        IReadOnlyList<CoffeeStation> filtered = _stationService.FilterStations(SearchQuery);
        Stations.Clear();
        foreach (CoffeeStation station in filtered)
        {
            Stations.Add(station);
        }

        SelectedStationBanner = filtered.Count == 0
            ? "לא נמצאו תחנות קפה התואמות לחיפוש."
            : $"נמצאו {filtered.Count} תחנות קפה על המפה.";
    }

    private bool CanExecuteClearFilter()
    {
        return !string.IsNullOrWhiteSpace(SearchQuery);
    }

    private void ExecuteClearFilter()
    {
        SearchQuery = string.Empty;
        ExecuteFilter();
    }

    private void ExecuteSelectStationByName(string? stationName)
    {
        if (string.IsNullOrWhiteSpace(stationName)) return;

        CoffeeStation? found = Stations.FirstOrDefault(s =>
            string.Equals(s.Name, stationName, StringComparison.OrdinalIgnoreCase));

        if (found is not null)
        {
            SelectedStation = found;
        }
    }

    private void UpdateBanner()
    {
        if (SelectedStation is null)
        {
            SelectedStationBanner = "לחצו על סיכה במפה כדי לראות פרטי תחנת קפה";
            return;
        }

        SelectedStationBanner = $"☕ {SelectedStation.Name} ({SelectedStation.Rating:0.0}★) — {SelectedStation.Specialty} | {SelectedStation.Address}";
    }
}
