using System.Windows.Input;
using MauiGoogleMapSample.Services;

namespace MauiGoogleMapSample.ViewModels;

public class SetupStatusViewModel : BaseViewModel
{
    private readonly IMapConfigurationValidator _validator;
    private readonly ISecureKeyStorageService _secureStorage;

    private string _apiKeyInput;
    private string _statusTitle = string.Empty;
    private string _statusDetails = string.Empty;
    private string _storageStatus = "טרם נשמר מפתח באחסון המוצפן (SecureStorage).";
    private bool _isConfigured;

    private readonly Command _validateKeyCommand;
    private readonly Command _saveKeyCommand;
    private readonly Command _clearSavedKeyCommand;

    public SetupStatusViewModel(
        IMapConfigurationValidator validator,
        ISecureKeyStorageService secureStorage)
    {
        _validator = validator;
        _secureStorage = secureStorage;
        Title = "CoffeeMap — שלב 1: התקנה והרשאות";
        _apiKeyInput = _validator.PlaceholderKey;

        _validateKeyCommand = new Command(ExecuteValidateKey, CanExecuteValidateKey);
        _saveKeyCommand = new Command(async () => await ExecuteSaveKeyAsync(), CanExecuteSaveKey);
        _clearSavedKeyCommand = new Command(ExecuteClearSavedKey);

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
            _saveKeyCommand.ChangeCanExecute();
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

    public string StorageStatus
    {
        get => _storageStatus;
        set
        {
            if (_storageStatus == value) return;
            _storageStatus = value;
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
            _saveKeyCommand.ChangeCanExecute();
        }
    }

    public ICommand ValidateKeyCommand => _validateKeyCommand;
    public ICommand SaveKeyCommand => _saveKeyCommand;
    public ICommand ClearSavedKeyCommand => _clearSavedKeyCommand;

    public async Task LoadSavedKeyAsync()
    {
        IsLoading = true;
        _saveKeyCommand.ChangeCanExecute();
        try
        {
            string? savedKey = await _secureStorage.GetApiKeyAsync();
            if (!string.IsNullOrWhiteSpace(savedKey))
            {
                ApiKeyInput = savedKey;
                ExecuteValidateKey();
                StorageStatus = "🔐 מפתח API נטען מהאחסון המוצפן (SecureStorage) וזמין לשאר המסכים.";
            }
            else
            {
                StorageStatus = "טרם נשמר מפתח באחסון המוצפן (SecureStorage).";
            }
        }
        catch (Exception ex)
        {
            StorageStatus = $"שגיאה בקריאה מ-SecureStorage: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
            _saveKeyCommand.ChangeCanExecute();
        }
    }

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

    private bool CanExecuteSaveKey()
    {
        return !IsLoading && _validator.ValidateApiKey(ApiKeyInput).IsValid;
    }

    public async Task ExecuteSaveKeyAsync()
    {
        ExecuteValidateKey();
        if (!IsConfigured) return;

        IsLoading = true;
        _saveKeyCommand.ChangeCanExecute();
        try
        {
            await _secureStorage.SaveApiKeyAsync(ApiKeyInput);
            StorageStatus = "🔐 המפתח נשמר בהצלחה באחסון המוצפן (SecureStorage) ונשלף אוטומטית בשאר המסכים.";
        }
        catch (Exception ex)
        {
            StorageStatus = $"שגיאה בשמירה ל-SecureStorage: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
            _saveKeyCommand.ChangeCanExecute();
        }
    }

    private void ExecuteClearSavedKey()
    {
        _secureStorage.ClearApiKey();
        ApiKeyInput = _validator.PlaceholderKey;
        ExecuteValidateKey();
        StorageStatus = "המפתח נמחק מהאחסון המוצפן והוחזר ל-Placeholder.";
    }
}
