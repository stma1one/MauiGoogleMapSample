using MauiGoogleMapSample.Services;
using MauiGoogleMapSample.ViewModels;
using Xunit;

namespace MauiGoogleMapSample.Tests;

public class SetupStatusViewModelTests
{
    [Fact]
    public void Constructor_InitializesWithPlaceholderAndInvalidStatus()
    {
        // Arrange
        var validator = new MapConfigurationValidator();

        // Act
        var vm = new SetupStatusViewModel(validator);

        // Assert
        Assert.Equal(validator.PlaceholderKey, vm.ApiKeyInput);
        Assert.False(vm.IsConfigured);
        Assert.Contains("Placeholder", vm.StatusTitle);
    }

    [Fact]
    public void ValidateKeyCommand_WhenApiKeyEmpty_CannotExecute()
    {
        // Arrange
        var vm = new SetupStatusViewModel(new MapConfigurationValidator());

        // Act
        vm.ApiKeyInput = "";

        // Assert
        Assert.False(vm.ValidateKeyCommand.CanExecute(null));
    }

    [Fact]
    public void ValidateKeyCommand_WhenValidKeyEntered_UpdatesIsConfiguredToTrue()
    {
        // Arrange
        var vm = new SetupStatusViewModel(new MapConfigurationValidator());

        // Act
        vm.ApiKeyInput = "AIzaSyFakeExampleKeyForUnitTests123456";
        vm.ValidateKeyCommand.Execute(null);

        // Assert
        Assert.True(vm.ValidateKeyCommand.CanExecute(null));
        Assert.True(vm.IsConfigured);
        Assert.Contains("תקין", vm.StatusTitle);
    }

    [Fact]
    public void ResetToPlaceholderCommand_RestoresPlaceholderAndInvalidState()
    {
        // Arrange
        var validator = new MapConfigurationValidator();
        var vm = new SetupStatusViewModel(validator);
        vm.ApiKeyInput = "AIzaSyFakeExampleKeyForUnitTests123456";
        vm.ValidateKeyCommand.Execute(null);

        // Act
        vm.ResetToPlaceholderCommand.Execute(null);

        // Assert
        Assert.Equal(validator.PlaceholderKey, vm.ApiKeyInput);
        Assert.False(vm.IsConfigured);
    }
}
