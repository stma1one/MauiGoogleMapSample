# Student Mastery Tracker

This tracker controls learning ownership. Keep theory and coding evidence separate so an explanation is not mistaken for independent implementation ability.

Allowed `Level` values:
- `Not introduced`
- `Practicing`
- `Understands`
- `Can work independently`

Rules:
- `Theory evidence`: the student explains purpose, data flow, choices, or predicted behavior in their own words.
- `Applied coding evidence`: the student independently authors or materially modifies a meaningful code block, then explains and verifies it in `CODE_LEARNING_REVIEWER`. Agent-generated code, copied code, approval, or explaining agent-written code never count.
- `Evidence source`: must name the actual student-authored file/method or checkpoint in this project. If `Evidence source` is `None` or unverifiable, `Routine eligibility` must be `No`.
- Only mark `Level: Can work independently` and `Routine eligibility: Yes` after both evidence tracks are recorded for the same concept.

## Concept Records

### Models
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Define domain model properties and types.

### Properties
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Implement backing fields and explicit getters/setters.

### INotifyPropertyChanged
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Implement explicit property setter with equality check and `OnPropertyChanged([CallerMemberName])`.

### ObservableCollection
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Bind and mutate an `ObservableCollection<T>` in a ViewModel.

### XAML binding
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Use `x:DataType` compiled bindings and typed `DataTemplate`s.

### Commands
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Wire `ICommand` / `Command` in a ViewModel and bind it in XAML.

### CanExecute
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Add a `CanExecute` predicate and trigger `ChangeCanExecute()` when dependent state changes.

### async/await
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Write async methods with `IsLoading`, `try/catch/finally`, and no `.Result` or `.Wait()`.

### DI
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Inject services via constructor and register Services, ViewModels, and Pages in `MauiProgram.cs`.

### Shell navigation
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Register routes in `AppShell` and navigate with `Shell.Current.GoToAsync`.

### validation
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Validate user input in the ViewModel and surface visual error feedback.

### testing
- Level: Not introduced
- Theory evidence: None
- Applied coding evidence: None
- Evidence source: None
- Routine eligibility: No
- Last demonstrated: None
- Needs practice: Propose edge cases and write Arrange-Act-Assert xUnit tests for ViewModel/Service logic.
