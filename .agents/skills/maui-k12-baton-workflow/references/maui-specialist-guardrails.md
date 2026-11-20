# MAUI Specialist Guardrails

Read this reference during `PLANNING_COACH`, `EXECUTION_AGENT`, `CODE_LEARNING_REVIEWER`, or `VERIFICATION_AUDITOR` whenever the slice touches architecture, ViewModels, Services, SQLite, XAML, Shell navigation, tests, style resources, audit, or Hebrew learning documentation. This file is the **Single Source of Truth** for .NET MAUI technical guardrails.

## Architecture, Vanilla C# MVVM, And State

- Keep the project student-readable. Avoid enterprise abstractions unless they remove real complexity.
- **Vanilla C# MVVM Core (No MVVM Source Generators, But CommunityToolkit UI & Messaging Are Allowed):**
  - Implement `INotifyPropertyChanged` and `ICommand` (`Command` / `Command<T>`) explicitly using standard C# properties, backing fields, and command wiring.
  - Do **not** use MVVM source-generator shortcuts or base classes that hide property/command mechanics: `[ObservableProperty]`, `[RelayCommand]`, `[NotifyCanExecuteChangedFor]`, `[NotifyPropertyChangedFor]`, or `ObservableObject` / `ObservableValidator`.
  - **Allowed CommunityToolkit usage:**
    - `CommunityToolkit.Maui` UI controls, popups, behaviors, and converters are **allowed**.
    - `WeakReferenceMessenger` (`CommunityToolkit.Mvvm.Messaging`) is **allowed** as the modern, memory-safe replacement for obsolete `MessagingCenter` when decoupled messaging is genuinely needed.
- Use clear MVVM boundaries:
  - View: layout, controls, visual states, bindings, accessibility.
  - ViewModel: UI state, commands, validation, service coordination.
  - Service: data access, APIs, persistence, platform operations.
  - Model: data representation.
- Prefer constructor dependency injection. Never instantiate services (`new SomeService()`) inside ViewModels.
- Do not perform network, database, or file work in constructors. Use an explicit async lifecycle method (such as `InitializeAsync()` invoked from page lifecycle) with loading/error handling.
- Avoid `.Result` and `.Wait()`.
- Use `async Task` for async work; reserve `async void` for required event handlers.
- **No Obsolete MAUI APIs:**
  - Do not use `Page.IsBusy` or `IsBusy = true` on pages; use ViewModel `IsLoading` plus `ActivityIndicator`.
  - In .NET 10 MAUI, use `DisplayAlertAsync`, `DisplayActionSheetAsync`, and `DisplayPromptAsync` instead of obsolete synchronous-named `DisplayAlert`, `DisplayActionSheet`, or `DisplayPrompt`.
  - Use `*Async` animation methods (`FadeToAsync`, `ScaleToAsync`, `TranslateToAsync`, `RotateToAsync`) instead of obsolete `FadeTo`, `ScaleTo`, `TranslateTo`, or `RotateTo`.
  - Use `CollectionView` instead of obsolete `ListView` or `TableView`.
  - Do not use obsolete `MessagingCenter` (use direct MVVM/Service coordination, C# events, or `WeakReferenceMessenger` from `CommunityToolkit.Mvvm.Messaging`) or obsolete `Device.BeginInvokeOnMainThread` (use `MainThread.BeginInvokeOnMainThread`).
- **Property Setters & `SetProperty(ref ...)` Soft-Gate Policy:**
  - **ViewModel Scope Only:** This rule applies strictly to `ViewModel` classes and `BaseViewModel` (`ViewModels/*.cs` or `*ViewModel.cs`).
  - **Custom Views Exemption:** Custom controls and views in `Views/` or `Controls/` (`BindableObject` / `ContentView`) that use `SetValue` or internal helper methods are explicitly exempt from this rule.
  - **Soft-Gate Workflow (Advisory Warning & Student Choice):** In ViewModels, prefer starting students with explicit 3-line property setters (`if (_field == value) return; _field = value; OnPropertyChanged();`). When `SetProperty(ref _field, value)` is encountered or proposed before `Learning/Student-Mastery.md` records mastery of `ref` and `SetProperty`, do **not** fail the build (`Scripts/Validate-Maui-ObsoleteApis.ps1/.sh` emits a non-blocking `[PEDAGOGICAL WARNING]` and exits `0`). Instead, briefly explain how `ref` parameter passing and backing-field updates work inside `SetProperty` and ask the student to choose:
    - **Option A (אפשרות א'):** Replace with the explicit 3-line setter (`if (_field == value) return; _field = value; OnPropertyChanged();` — recommended for Bagrut clarity).
    - **Option B (אפשרות ב'):** Keep `SetProperty(ref _field, value)`, learn the `ref` concept now, and record it in `Learning/Student-Mastery.md` (and explain it in `Learning/MAUI-Learning-Book.md`).
- Prefer `ICommand.CanExecute` over explicit `IsEnabled` bindings in XAML buttons and interactive controls. Use `CanExecute` with a meaningful condition and refresh it via `ChangeCanExecute()` / `CanExecuteChanged` when relevant state changes.

## Targeted Documentation Verification (High-Friction Triggers)

Do not perform redundant web searches for routine C# or MVVM code.
However, you MUST actively query official documentation (Microsoft Learn for MAUI, Firebase for Google services) when encountering any of these **High-Friction Triggers**:

1. **Native & Storage NuGet Packages**:
   - When adding or choosing packages for SQLite, local storage, or platform bindings.
   - Purpose: Ensure zero package conflicts and correct platform provider bundles.
2. **Platform & Device-Specific Features**:
   - When using `Map` (`Microsoft.Maui.Controls.Maps` — https://learn.microsoft.com/en-us/dotnet/maui/user-interface/controls/map?view=net-maui-10.0 and Google Maps Android API Key setup in Hebrew: https://developers.google.com/maps/documentation/android-sdk/get-api-key?hl=he), `WebView`, `MediaPicker`, `Geolocation`, `Permissions`, or native hardware controls.
   - Purpose: Ensure correct MAUI-specific XAML controls, `.UseMauiMaps()` builder registration, Android manifest metadata/permissions, and lifecycle methods are used (not Web or standard desktop idioms).
3. **Cloud, AI & Third-Party SDK Integration**:
   - **Google AI / Gemini API (Single Source of Truth):** When integrating Google Gemini / Generative AI in .NET MAUI, use **https://googleapis.github.io/dotnet-genai/** (the official `Google.GenAI` .NET SDK) as the authoritative source of truth.
   - When integrating Firebase, Firestore, Authentication providers, or Azure services in a MAUI client.
   - Purpose: Verify current recommended mobile/.NET SDK architecture, initialization hooks, structured output (`GenerateContentConfig`), and credentials handling.
4. **Platform Crash / Native Diagnostics**:
   - When encountering native symbol collisions, P/Invoke failures, or platform sandbox exceptions.

## Approved Google AI / Gemini .NET SDK (`Google.GenAI` — Single Source of Truth)

When a student project integrates Google AI / Gemini (for example, to fulfill Ministry of Education 5-unit Bagrut Section 5 paths `AI-1`, `AI-2`, or `AI-3`):

- **Authoritative Documentation (Single Source of Truth):** **https://googleapis.github.io/dotnet-genai/**
- **Approved NuGet Package:** **`Google.GenAI`** (**latest Stable version**, `>= 2.2.0`, installed via `dotnet add package Google.GenAI`). Do not use deprecated/unofficial legacy wrappers or raw unstructured REST calls when `Google.GenAI` is applicable.
- **Architecture, Mobile Android Rules & Implementation Guidelines:**
  - **Dedicated Service Layer (`Services/`):** Encapsulate all `Google.GenAI` calls inside a dedicated Service class implementing an interface (e.g., `IGeminiAiService` / `GeminiAiService`), injected into ViewModels via constructor DI. Never call `Google.GenAI.Client` directly from a View or ViewModel.
  - **Mobile Authentication (`apiKey` Only — Never `vertexai: true` on Android/iOS):**
    - On mobile devices (.NET MAUI Android/iOS), always initialize `var client = new Client(apiKey: apiKey);` using a Gemini Developer API key loaded from `SecureStorage`, user settings, or a git-ignored local config.
    - **Never** pass `vertexai: true` in a mobile MAUI client (Vertex AI relies on server Application Default Credentials / local gcloud files that do not exist on Android and fail at runtime).
    - **Never** commit a hardcoded real Google API key (`AIzaSy...`) into source control.
  - **Android `INTERNET` Permission (`Platforms/Android/AndroidManifest.xml`):**
    - Verify that `Platforms/Android/AndroidManifest.xml` includes `<uses-permission android:name="android.permission.INTERNET" />`.
  - **Official SDK Call Patterns (https://googleapis.github.io/dotnet-genai/):**
    - Call `await client.Models.GenerateContentAsync(model: "gemini-2.5-flash", contents: ..., config: ...);`.
    - For **`AI-1` (Structured Output / JSON Schema)**: configure `GenerateContentConfig` with `ResponseMimeType = "application/json"` and `ResponseSchema` (or `ResponseJsonSchema`), then deserialize (`JsonSerializer.Deserialize<T>()`) into strongly-typed C# domain models integrated into app logic/SQLite.
    - For **`AI-3` (Runtime AI Agent / Function Calling)**: configure `GenerateContentConfig` with `Tools` declarations and invoke internal C# service methods based on the returned function calls.
- **Unit Testing `Google.GenAI` in `xunit.v3` (Student & Agent Testing Plan):**
  - Never make live network calls to Google Gemini inside `xunit.v3` unit tests (`<AppName>.Tests`).
  - Instead, teach and implement two complementary unit-test patterns:
    1. **ViewModel Tests with a Fake AI Service (`FakeGeminiAiService : IGeminiAiService`):** Test how the `ViewModel` handles `IsLoading`, `CanExecute`, valid structured AI results, and exception/error recovery when the AI service succeeds or throws.
    2. **Service JSON-Schema Parsing Tests (`ParseStructuredResponse(string rawJson)`):** Separate the JSON deserialization/validation logic into a public or internal testable method on the AI Service so `xunit.v3` tests verify valid JSON deserialization, missing required fields, and malformed JSON handling without needing an active internet connection or API key.

## Approved SQLite Stack & Latest-Stable NuGet Policy (Non-Negotiable)

- **Always Install the Latest Stable NuGet Version:**
  - Never hardcode stale NuGet package version numbers from training memory into `.csproj` files (such as old `1.8.x` / `1.9.x` versions of `sqlite-net-pcl` or legacy `2.x` versions of `xunit`).
  - Always install NuGet packages using `dotnet add package <PackageId>` (without `--prerelease`) so the .NET CLI resolves the **latest Stable version** from NuGet.org, or query `https://api.nuget.org/v3-flatcontainer/<package-id-lowercase>/index.json` and pick the highest non-prerelease version.
  - `Scripts/Validate-Maui-Version.ps1/.sh` automatically checks every `<PackageReference>` across all `.csproj` files against NuGet.org (with offline minimum-stable baselines: `Google.GenAI >= 2.2.0`, `sqlite-net-pcl >= 1.11.285`, `SQLitePCLRaw.bundle_green >= 2.1.11`, `SQLiteNetExtensions >= 2.1.0`, `SQLiteNetExtensions.Async >= 2.1.0`, `xunit.v3 >= 4.0.3`, `xunit.runner.visualstudio >= 4.0.1`) and fails if any package is outdated, uses an unintended prerelease, or uses legacy `xunit` v2 (run `.\Scripts\Validate-Maui-Version.ps1 -Fix` to auto-upgrade).

For any student project that persists data in SQLite, use only:

1. `sqlite-net-pcl` (**latest Stable version**, `>= 1.11.285`) for basic CRUD operations with `SQLiteAsyncConnection`. Follow Microsoft's MAUI SQLite guide: https://learn.microsoft.com/en-us/dotnet/maui/data-cloud/database-sqlite?view=net-maui-10.0
2. `SQLiteNetExtensions` (and `SQLiteNetExtensions.Async`, **latest Stable version**, `>= 2.1.0`, when using async relationship helpers such as `GetWithChildrenAsync`, `InsertWithChildrenAsync`, or `UpdateWithChildrenAsync` on `SQLiteAsyncConnection`) in addition to `sqlite-net-pcl` only when the model needs relationships:
   - One-to-one: https://www.codejourney.net/sqlite-net-extensions-one-to-one-relationships/
   - One-to-many: https://www.codejourney.net/sqlite-net-extensions-one-to-many-relationships/
   - Many-to-many: https://www.codejourney.net/sqlite-net-extensions-many-to-many-relationships/
   - Note: You may also manage 1:N foreign-key queries explicitly using `SQLiteAsyncConnection.Table<T>().Where(...)` in the Service layer so students clearly see how foreign keys work.

Do not use or add Entity Framework Core SQLite (`Microsoft.EntityFrameworkCore.Sqlite`), `Microsoft.Data.Sqlite`, `System.Data.Sqlite`, Dapper, LiteDB, or any other ORM/provider. Do not replace `sqlite-net-pcl` with `SQLiteNetExtensions`; the extension packages are strictly additive.

Implementation rules:
- Keep database operations in a Service/Repository, never in a View or ViewModel.
- Always use async APIs (`SQLiteAsyncConnection`); never block the UI thread with synchronous `SQLiteConnection`, `.Result`, or `.Wait()`.
- For relationships, explicitly identify the cardinality (`[OneToOne]`, `[OneToMany]`, `[ManyToMany]`, `[ForeignKey]`) and either use `SQLiteNetExtensions.Async` helpers on `SQLiteAsyncConnection` or explicit async queries in the Service. Never assume relationship loading happens automatically.

## XAML UI

- For Hebrew-first apps, set `FlowDirection="RightToLeft"` at Shell or page level. Do not force RTL onto URLs, emails, code, or identifiers.
- Prefer compiled bindings with `x:DataType` when the binding context is known.
- Always type `DataTemplate` contexts.
- Do not use untyped bindings to silence warnings.
- Use the simplest suitable layout: `Grid`, `VerticalStackLayout`, `HorizontalStackLayout`, `FlexLayout`, or `CollectionView`.
- Avoid arbitrary fixed page dimensions.
- Important controls need meaningful labels, readable states, and accessible touch targets.
- Prefer ViewModel validation state plus binding, `DataTrigger`, or `VisualStateManager`.
- Every `StaticResource`, `DynamicResource`, `BasedOn`, and `x:Key` reference must resolve in scope (either within the same XAML file's `Resources` or in `App.xaml` / `Resources/Styles/*.xaml`).
- Put shared styles in `Resources/Styles/Styles.xaml`, shared colors in `Resources/Styles/Colors.xaml`, and page-specific styles in page resources.

## Maps Integration (`Microsoft.Maui.Controls.Maps` — Single Source of Truth)

When a student project integrates interactive maps (for example, to fulfill Ministry of Education 5-unit Bagrut Section 9 topic `9.4` — שילוב מפות ושימוש בנתוני מיקום):

- **Authoritative .NET MAUI Map Documentation:** **https://learn.microsoft.com/en-us/dotnet/maui/user-interface/controls/map?view=net-maui-10.0**
- **Authoritative Google Maps Android API Key Guide (Hebrew):** **https://developers.google.com/maps/documentation/android-sdk/get-api-key?hl=he**
- **Required Setup & Configuration Checklist:**
  1. **NuGet Package:** Install `Microsoft.Maui.Controls.Maps` (`dotnet add package Microsoft.Maui.Controls.Maps` or `Version="$(MauiVersion)"`).
  2. **`MauiProgram.cs` Registration:** Chain `.UseMauiMaps()` onto `MauiAppBuilder` inside `CreateMauiApp()`:
     ```csharp
     builder
         .UseMauiApp<App>()
         .UseMauiMaps();
     ```
  3. **Google Maps Android SDK API Key & `Platforms/Android/AndroidManifest.xml`:**
     - Guide the student to create a Google Maps Android API Key using the official Hebrew instructions: https://developers.google.com/maps/documentation/android-sdk/get-api-key?hl=he
     - In `Platforms/Android/AndroidManifest.xml`, add `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_GOOGLE_MAPS_API_KEY" />` inside `<application>...</application>`, and declare location permissions (`ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`) inside `<manifest>...</manifest>`. (Warn the student not to commit an unrestricted production billing key to a public repository).
  4. **XAML & MVVM Data Binding (`xmlns:maps="http://schemas.microsoft.com/dotnet/2021/maui/maps"`):**
     - Bind pins cleanly from an `ObservableCollection<PinModel>` in the ViewModel using `ItemsSource` and `ItemTemplate` (`<maps:Pin Location="{Binding Location}" Label="{Binding Label}" Address="{Binding Address}" />`).
     - Request runtime location permissions (`Permissions.RequestAsync<Permissions.LocationWhenInUse>()`) before setting `IsShowingUser="True"` or calling `Geolocation.Default.GetLocationAsync()`.
  5. **Platform Support & Android Verification Note:**
     - As documented in https://learn.microsoft.com/en-us/dotnet/maui/user-interface/controls/map?view=net-maui-10.0, `Microsoft.Maui.Controls.Maps` renders natively on **Android, iOS, and Mac Catalyst** (not on Windows WinUI desktop). Always verify and capture live map screenshots on the **Android emulator/device** (or provide an Android-framed mockup fallback if offline).
  6. **Unit Testing Map & Location Logic in `xunit.v3`:**
     - Keep distance calculations (`Location.CalculateDistance`), pin filtering, and radius searches inside a ViewModel or Service method (using `ILocationService` fake in tests) so `xunit.v3` tests verify location filtering and pin generation without instantiating the native `Map` UI control.

## Shell Navigation

- Use Shell as the primary navigation system for Shell-based student projects.
- Root hierarchy belongs in `AppShell.xaml`.
- Detail pages use registered routes.
- Prefer route names based on `nameof(PageType)` when practical.
- Navigate with `Shell.Current.GoToAsync(...)`; back navigation uses `".."`.
- Pass small parameters through `Dictionary<string, object>`.
- Prefer passing IDs over large objects when the destination can load data itself.
- Use `IQueryAttributable` or another current documented Shell mechanism when receiving parameters.
- Register Pages and ViewModels in DI when Shell or constructors need to resolve them.
- Do not create an `INavigationService` wrapper unless tests or project requirements justify it.

## Tests

- **Configuration in `.agents/MAUI-Agent-Mode.json` (`includeTests` & `testManagementMode`):**
  - `includeTests` (boolean, default `true`): When `false`, skip xUnit test provisioning/validation and ignore `testManagementMode`.
  - `testManagementMode` (`"combined"` | `"agent"` | `"student"`, default `"combined"`):
    - In `MAXIMIZE CODE GENERATED` (`studentCapabilityMode: false`), when `includeTests: true`, ignore `testManagementMode` — the **agent ALWAYS writes and runs all xUnit tests** (`>= 1` test per new `ViewModel` / `Service` / `Converter`) and documents every test in **`Learning/Test-Documentation.md`**.
    - In `MAXIMIZE STUDENT CAPABILITY` (`studentCapabilityMode: true`) when `includeTests: true`:
      - `"combined"` (Default): Agent creates core/scaffold xUnit tests, explains at the end of each stage/slice the tests that were created, offers selected test cases for the student to write, and documents all tests in `Learning/Test-Documentation.md`.
      - `"agent"`: Agent independently writes and runs the xUnit tests and documents them in `Learning/Test-Documentation.md`.
      - `"student"`: Agent guides the student in writing the xUnit tests through Socratic dialogue to verify understanding of required test scenarios.
- **Automatic Provisioning (`xunit.v3` Latest Stable) & MAUI `net10.0` / `net11.0` Multi-Targeting (`Scripts/Ensure-Test-Project.ps1/.sh/.py`):**
  - Always use **`xunit.v3`** (latest Stable version `>= 4.0.3`, with `xunit.runner.visualstudio >= 4.0.1`, `<OutputType>Exe</OutputType>`, and `global.json` `"test": { "runner": "Microsoft.Testing.Platform" }`). **Never** install legacy `xunit` v2 (`2.x`).
  - Creates `<AppName>.Tests` (`<AppName>.Tests.csproj` with latest stable `xunit.v3`), adds it to `.sln`/`.slnx`, and links it to `<AppName>.csproj`.
  - Adds the plain base TFM (`net10.0` or `net11.0`, or `net9.0`/`net8.0`) to `<TargetFrameworks>` in the MAUI `.csproj` (alongside `net10.0-android`, `net10.0-windows...`), conditions `<OutputType>Exe</OutputType>` so the plain TFM compiles as a library, and excludes `Platforms/**` on the plain TFM so `xunit.v3` compiles and runs tests directly against `ViewModels`, `Services`, `Converters`, and `Models` without an emulator.
- Use `xunit.v3` for ViewModel, Service, and Converter behavior.
- Use Arrange, Act, Assert (AAA) and document all tests in Hebrew (with English identifiers) in `Learning/Test-Documentation.md` so the student can explain them to the Bagrut examiner.
- Prefer descriptive names such as `SaveCommand_WhenFormInvalid_CannotExecute`.
- Async tests use `async Task`.
- Test behavior, not XAML visual trees.
- Cover initial state, success, failure, validation, loading state, error state, collection updates, command behavior, and `CanExecute` where relevant.
- Use simple manual fakes when mocking libraries are not allowed.
- Reject weak tests such as `Assert.NotNull(vm)` when they cannot fail for the behavior under test.

## Verification Audit

Before declaring `Status: COMPLETE` in `VERIFICATION_AUDITOR`, verify with evidence:

```text
1. Target framework/version (net8.0 / net9.0 / net10.0 / net11.0, including plain net10.0/net11.0 TFM when includeTests=true)
2. Current MAUI compatibility (no obsolete APIs)
3. Build (dotnet build)
4. Architecture boundaries (no Services instantiated in ViewModels)
5. DI registration in MauiProgram.cs
6. Navigation routes & DI
7. Compiled Bindings (x:DataType)
8. Styles/resources scope resolution
9. State/commands & CanExecute
10. Async/error handling (no .Result / .Wait() / constructor I/O)
11. Unit Tests (when includeTests=true: *.Tests.csproj exists, every new ViewModel/Service/Converter is tested, Validate-Tests passes with Passed >= 1 and Failed == 0, and Learning/Test-Documentation.md is updated)
12. Learning documentation, screen visual artifacts (`Learning/Images/`), and compiled PDF learning book (`Learning/MAUI-Learning-Book.pdf` + `Learning/MAUI-Learning-Book.validation.json`)
```

Run available checks:

**Windows (PowerShell):**
```powershell
dotnet build
.\Scripts\Ensure-Test-Project.ps1
.\Scripts\Validate-Tests.ps1
.\Scripts\Validate-Maui-Version.ps1
.\Scripts\Validate-Maui-ObsoleteApis.ps1
.\Scripts\Validate-Maui-XamlResources.ps1
.\Scripts\Audit-DI.ps1
.\Scripts\Validate-Bagrut-Compliance.ps1
.\Scripts\Generate-Architecture-Diagrams.ps1
python .\Scripts\Generate-Learning-Book-Pdf.py
.\Scripts\Validate-Learning-Book.ps1
```

**macOS / Linux (Bash):**
```bash
dotnet build
./Scripts/Ensure-Test-Project.sh
./Scripts/Validate-Tests.sh
./Scripts/Validate-Maui-Version.sh
./Scripts/Validate-Maui-ObsoleteApis.sh
./Scripts/Validate-Maui-XamlResources.sh
./Scripts/Audit-DI.sh
./Scripts/Validate-Bagrut-Compliance.sh
./Scripts/Generate-Architecture-Diagrams.sh
python3 ./Scripts/Generate-Learning-Book-Pdf.py
./Scripts/Validate-Learning-Book.sh
```

Never claim `Status: COMPLETE` without concrete execution evidence — including both a passing `dotnet build` and a compiled, validated `Learning/MAUI-Learning-Book.pdf` (`Learning/MAUI-Learning-Book.validation.json` passing and at least one image in `Learning/Images/` for every screen). If a check cannot run in the current environment, state the limitation clearly and use `Status: READY_TO_VERIFY`. If any check fails, use `Status: BLOCKED`.

In Student Capability Mode, also verify:
- the plan was approved or planning decisions were documented
- concept-gate evidence exists
- ownership split was chosen before execution
- agent-owned and student-owned tasks are recorded
- `Learning/Student-Mastery.md` keeps theory evidence separate from applied coding evidence with a real `Evidence source`
- no agent-generated, copied, or merely explained code is recorded as applied coding evidence
- agent-owned routine work is limited to concepts recorded with both evidence tracks and `Routine eligibility: Yes`

## Learning Documentation (Hebrew with English Identifiers)

Maintain `Learning/MAUI-Learning-Book.md` as append-only.

**Language Rule (Mandatory):**
- Write all explanations, architectural rationale, and guidance in `Learning/MAUI-Learning-Book.md` and `Learning/Guides/<ScreenName>-Guide.md` in **Hebrew**.
- Keep all C#, XAML, SQL, and .NET code identifiers, class names, properties, attributes, and file paths in **English**.

For each meaningful code change, document:
- current phase and baton workflow stage
- planning decision or concept gate
- ownership split (what the student did vs. what the agent changed)
- why the architecture was chosen
- how to verify
- Do not write generic textbook lessons. Teach the actual project change.

### Step-by-Step Learning Books and UI Guides

When documenting a screen, page, UI feature, or existing-project learning journey, use the `maui-step-guide-author` methodology:
- For an existing project, map current files and behavior with the student before proposing milestones to the end goal.
- Do not dump monolithic XAML or ViewModel files. Provide small source-grounded blocks with their file/layer, rationale, evidence, and a student checkpoint.
- Create an HTML visual model at `Learning/Mockups/<ScreenName>.html` only when it teaches the screen composition; label it as a model rather than emulator evidence.
- Capture the marked overview and individual blocks with `Capture-Mockup-Blocks.py`, then embed the generated images in the matching guide sections.
- Write all guide prose in **Hebrew** while preserving XAML elements, C# identifiers, and commands in **English**.
- Save each screen guide at `Learning/Guides/<ScreenName>-Guide.md`, index it in `Learning/MAUI-Learning-Book.md`, and require the generated book validation report to pass before publication.

## Student Review Tone

Use supportive review:

```text
What is good
What to improve
Why it matters
Smallest useful fix
```

Do not help disguise generated work. Help the student understand, simplify, and explain it.

## 10. MAUI DevFlow Runtime Inspection & External Skill Precedence

- **Allowed Debug-Only Package (`.NET 10` / `.NET 11` Only)**: `Microsoft.Maui.DevFlow.Agent` ([NuGet](https://www.nuget.org/packages/Microsoft.Maui.DevFlow.Agent/), [Microsoft Learn DevFlow Docs](https://learn.microsoft.com/en-us/dotnet/maui/developer-tools/devflow/?view=net-maui-10.0)) is explicitly permitted for live visual-tree inspection, binding verification, UI automation, and screenshot capture on `net10.0` and `net11.0` projects, provided:
  1. In `.csproj`, the `PackageReference` is strictly conditioned on `Debug` (`Condition="'$(Configuration)' == 'Debug'"` on either the `<ItemGroup>` or `<PackageReference>`).
  2. In `MauiProgram.cs`, `using Microsoft.Maui.DevFlow.Agent;` and `builder.AddMauiDevFlowAgent();` are wrapped strictly inside `#if DEBUG ... #endif`.
  3. The package is documented in `Learning/AI-And-External-Code-Attribution.md` (with no inline AI attribution comments in `.cs` or `.xaml`).
- **Two-Layer TFM-Aware Provisioning & Opt-Out (`Scripts/Ensure-Maui-DevFlow.py` / `.ps1` / `.sh`)**: Invoked by `Install-Skill.ps1/.sh` and `Scripts/Setup-Skills.ps1/.sh` (unless opted out with `-SkipDevFlow` / `--skip-devflow` / `--no-devflow`). It checks `<TargetFramework>` / `<TargetFrameworks>` first and provisions **two layers** when the project targets `net10.0` or `net11.0` (skipping `net9.0` and older targets such as `net9.0-android`):
  1. **Project Layer (NuGet):** Injects the pinned `0.1.0-preview.14.26531.2` `Microsoft.Maui.DevFlow.Agent` package into `.csproj` (`Condition="'$(Configuration)' == 'Debug'"`) and `#if DEBUG` `builder.AddMauiDevFlowAgent();` into `MauiProgram.cs`.
  2. **Machine Layer (Global CLI):** Installs or updates the global `.NET MAUI DevFlow CLI` (`dotnet tool install -g Microsoft.Maui.Cli --prerelease` / `dotnet tool update -g Microsoft.Maui.Cli --prerelease` when `-Upgrade` / `--upgrade` is passed). Use `-SkipCli` / `--skip-cli` (`MAUI_SKIP_DEVFLOW_CLI=1`) when working without global tool permissions, or `--remove` / `-Remove` to remove project DevFlow injection.
- **Release Leak Validation**: `Scripts/Validate-Maui-ObsoleteApis.ps1/.sh` fails with `[RELEASE LEAK]` if `Microsoft.Maui.DevFlow` appears in `.csproj` without a strict positive `Debug` condition (blocking `Condition="'$(Configuration)' != 'Debug'"`) or if `AddMauiDevFlowAgent()` / `using Microsoft.Maui.DevFlow` is called outside `#if DEBUG` (blocking `#if !DEBUG`, `#else`, and `#elif`).
- **Stage 7 Mandatory Visual & PDF Blocking Gate (`VERIFICATION_AUDITOR` — Android + Architecture/UML PNGs + PDF)**: `Status: COMPLETE` is strictly blocked until one of the two visual routes is completed for every screen, the Architecture & UML visual PNGs are generated, AND the PDF learning book is compiled and validated:
  - **Route A (Live `MAUI DevFlow` / Android Emulator — when installed and working):** Prefer running on Android (`dotnet build -t:Run -f net10.0-android` + `adb reverse tcp:9223 tcp:9223`) and capturing `Learning/Images/<ScreenName>-android.png` via `maui devflow MAUI screenshot` or `adb exec-out screencap -p > Learning/Images/<ScreenName>-android.png`. Never rely solely on a Windows desktop (`*-windows.png`) screenshot; if testing on Windows without a live Android emulator, also run `Capture-Mockup-Blocks.py` to generate the Android 14 smartphone-framed `<ScreenName>-android.png`.
  - **Route B (Mandatory Fallback — REQUIRED whenever `MAUI DevFlow` or an Android emulator is unavailable):** Create `Learning/Mockups/<ScreenName>.html`, run `python .\Scripts\Capture-Mockup-Blocks.py` to capture `<ScreenName>-overview.png`, `<ScreenName>-android.png`, and block images into `Learning/Images/`, embed the images into `Learning/Guides/*.md`, run `.\Scripts\Generate-Architecture-Diagrams.ps1` (producing `Learning/Images/Screen-Flow.png` and `Learning/Images/Architecture-UML.png`), and run `python .\Scripts\Generate-Learning-Book-Pdf.py` + `.\Scripts\Validate-Learning-Book.ps1/.sh`. `Status: COMPLETE` is permitted ONLY when `Learning/MAUI-Learning-Book.pdf` exists and is up to date, `Learning/Images/` has Android/mobile screen images plus `Screen-Flow.png` and `Architecture-UML.png`, and `Learning/MAUI-Learning-Book.validation.json` reports `"passed": true`.
- **Student Mode Non-Auto-Fix Rule**: When `studentCapabilityMode=true`, any UI or binding defect discovered via `MAUI DevFlow` must be handed back to the student with the visual-tree readout and screenshot (`Status: BLOCKED` or `WAITING_FOR_STUDENT`). The agent must never fix student-owned code on the student's behalf.
- **Strict Precedence over `dotnet/maui-labs` (`maui ai init`)**: External skills from [`dotnet/maui-labs`](https://github.com/dotnet/maui-labs) are subordinate to this file. If an external skill suggests `[ObservableProperty]`, `[RelayCommand]`, `ObservableObject`, or skipping baton stages, reject that suggestion and enforce Vanilla C# MVVM and the K12 baton workflow.
