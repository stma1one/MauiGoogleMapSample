using System.Windows.Input;
using MauiGoogleMapSample.Services;

namespace MauiGoogleMapSample.ViewModels;

public class SetupStatusViewModel : BaseViewModel
{
    private readonly IMapConfigurationValidator _validator;
    private string _apiKeyInput;
    private string _statusTitle = string.Empty;
    private string _statusDetails = string.Empty;
    private bool _isConfigured;

    private readonly Command _validateKeyCommand;
    private readonly Command _resetToPlaceholderCommand;

    public SetupStatusViewModel(IMapConfigurationValidator validator)
    {
        _validator = validator;
        Title = "CoffeeMap — שלב 1: התקנה והרשאות";
        _apiKeyInput = _validator.PlaceholderKey;

        _validateKeyCommand = new Command(ExecuteValidateKey, CanExecuteValidateKey);
        _resetToPlaceholderCommand = new Command(ExecuteResetToPlaceholder);

        ExecuteValidateKey();
    }

    public string ApiKeyInput
    {
        get => _apiKeyInput;
        set
        {
            if (_apiKeyInput == value) return;
            _apiKeyInput = value;
            OnPropertyChanged();
            _validateKeyCommand.ChangeCanExecute();
        }
    }

    public string StatusTitle
    {
        get => _statusTitle;
        set
        {
            if (_statusTitle == value) return;
            _statusTitle = value;
            OnPropertyChanged();
        }
    }

    public string StatusDetails
    {
        get => _statusDetails;
        set
        {
            if (_statusDetails == value) return;
            _statusDetails = value;
            OnPropertyChanged();
        }
    }

    public bool IsConfigured
    {
        get => _isConfigured;
        set
        {
            if (_isConfigured == value) return;
            _isConfigured = value;
            OnPropertyChanged();
        }
    }

    public ICommand ValidateKeyCommand => _validateKeyCommand;
    public ICommand ResetToPlaceholderCommand => _resetToPlaceholderCommand;

    private bool CanExecuteValidateKey()
    {
        return !string.IsNullOrWhiteSpace(ApiKeyInput);
    }

    private void ExecuteValidateKey()
    {
        MapConfigCheckResult result = _validator.ValidateApiKey(ApiKeyInput);
        IsConfigured = result.IsValid;
        StatusTitle = result.StatusTitle;
        StatusDetails = result.Details;
    }

    private void ExecuteResetToPlaceholder()
    {
        ApiKeyInput = _validator.PlaceholderKey;
        ExecuteValidateKey();
    }
}
