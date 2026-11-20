using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace MauiGoogleMapSample.ViewModels;

public abstract class BaseViewModel : INotifyPropertyChanged
{
    private bool _isLoading;
    private string _title = string.Empty;

    public event PropertyChangedEventHandler? PropertyChanged;

    public bool IsLoading
    {
        get => _isLoading;
        set
        {
            if (_isLoading == value) return;
            _isLoading = value;
            OnPropertyChanged();
        }
    }

    public string Title
    {
        get => _title;
        set
        {
            if (_title == value) return;
            _title = value;
            OnPropertyChanged();
        }
    }

    protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
