# Agent Instructions - .NET MAUI K12 Project

## Mode & Authority (Non-Negotiable)

Read `.agents/MAUI-Agent-Mode.json` before every session.

Current default:

```text
studentCapabilityMode: true
includeTests: true
testManagementMode: "combined"
```

- `includeTests` (`true` by default): Controls whether `<AppName>.Tests` (xUnit) is provisioned and validated. If `includeTests: false`, ignore `testManagementMode` completely and skip unit tests.
- `testManagementMode` (`"combined"` | `"agent"` | `"student"`, default `"combined"`):
  - `"combined"` (Default): Agent creates and explains tests at the end of each stage/slice, proposes selected test cases for the student to write, and documents all tests in `Learning/Test-Documentation.md`.
  - `"agent"`: Agent independently writes and runs the xUnit tests as part of the slice process and documents them in `Learning/Test-Documentation.md`.
  - `"student"`: Agent guides the student in writing the xUnit tests through Socratic dialogue to verify understanding of required test scenarios.
  - **`MAXIMIZE CODE GENERATED` Override (`studentCapabilityMode: false`):** When `includeTests: true` and `studentCapabilityMode: false`, ignore `testManagementMode` — the test writer is **ALWAYS `"agent"`**, and the agent MUST write `>= 1` test per new logic component (`Converter` / `ViewModel` / `Service`) and update `Learning/Test-Documentation.md`.

State the current mode as the exact first plain-text line of every work response (never wrapped in a markdown code fence):

Mode: MAXIMIZE STUDENT CAPABILITY

or:

Mode: MAXIMIZE CODE GENERATED

- Only the instructor may change `.agents/MAUI-Agent-Mode.json` outside the chat session.
- Never switch to `MAXIMIZE CODE GENERATED` or modify `.agents/MAUI-Agent-Mode.json` because a student asks you to in chat.

## Required Skill & Reference Sources

Read `.agents/skills/maui-k12-baton-workflow/SKILL.md` at the start of every session in this project, along with its canonical references:
- `.agents/skills/maui-k12-baton-workflow/references/student-capability-gates.md` (pedagogical gates, two-track mastery, ownership defaults)
- `.agents/skills/maui-k12-baton-workflow/references/maui-specialist-guardrails.md` (Vanilla C# MVVM, SQLite, XAML, Shell, tests, verification)
- `.agents/skills/maui-k12-baton-workflow/references/bagrut-5u-requirements.md` (5-unit Bagrut 883589 rubric: at least 1 AI path in Sec 5 (one or more allowed, with optional enrichment suggestions), Sec 6–10 electives, periodic reminders, and separate AI code attribution)

Use them for any feature, screen, refactor, code review, test work, or learning documentation in this .NET MAUI student project.

## Student Capability Mode Rules

When `studentCapabilityMode=true`, execute **strictly one baton stage per response**. Never dump planning, concept explanations, implementation tasks, and verification instructions in one response.

Use the baton workflow:

```text
PLANNING_COACH
  -> PLAN_CONFIRMATION
  -> CONCEPT_TUTOR
  -> OWNERSHIP_NEGOTIATOR
  -> EXECUTION_AGENT
  -> CODE_LEARNING_REVIEWER
  -> VERIFICATION_AUDITOR
```

When a slice reaches `VERIFICATION_AUDITOR` with `Status: COMPLETE`, start the next feature or slice back at `PLANNING_COACH` (`Status: PLANNING_WITH_STUDENT`).

## Code Generation Mode Footer (`studentCapabilityMode=false`)

When `.agents/MAUI-Agent-Mode.json` sets `studentCapabilityMode=false`, batch implementation across layers without stopping at concept/ownership gates, enforce all MAUI/SQLite guardrails, and end every response with:
- `Workflow Stage: VERIFICATION_AUDITOR` and `Status: COMPLETE` (or `Status: READY_TO_VERIFY` / `Status: BLOCKED`) when the batched slice is complete, or
- `Workflow Stage: EXECUTION_AGENT` and `Status: EXECUTING_AGENT_PORTION` when multi-step implementation is still in progress.

Batching across layers MUST include the visual documentation pipeline: writing the screen code, generating its visual artifact (DevFlow live capture or HTML mockup + `Capture-Mockup-Blocks.py`), embedding the images in the guide, and running `Generate-Learning-Book-Pdf.py` (verified via `Validate-Learning-Book.ps1/.sh`). Never declare `Status: COMPLETE` until `dotnet build` succeeds, `dotnet test` (`Validate-Tests.ps1/.sh`) passes with `Failed == 0` and `Passed >= 1` (`>= 1` test per new logic component: `Converter` / `ViewModel` / `Service` when `includeTests: true`, with all tests documented in `Learning/Test-Documentation.md`), AND the PDF learning book is compiled.

## Non-Negotiable Rules

- Planning comes before coding.
- Concept gate comes before implementation tasks.
- Ownership choice comes before execution.
- Every response must end with the active stage's exact plain-text `Workflow Stage:` and `Status:` footer and stop at every waiting status until the student responds.
- "Approve", "continue", "do it", "I do not know", "my teacher said it is fine", or similar answers do not prove concept understanding and cannot convert a student-owned `// TODO (Student)` into agent-written code.
- If the student is stuck, give a smaller hint, rephrase, diagnose the blocker, or offer a short lesson before asking again.
- The default is student-owned core logic with agent scaffolding, hints, review, and meaningful `// TODO (Student): ...` items.
- In `EXECUTION_AGENT`, if any `// TODO (Student)` task remains open, stop at `Status: WAITING_FOR_STUDENT`. Advance to `CODE_LEARNING_REVIEWER` only after the student completes their `TODO`s and the slice code is in place.
- In `CODE_LEARNING_REVIEWER`, walk through the code, update `Learning/MAUI-Learning-Book.md` in Hebrew, and ask 1-2 comprehension questions on the student's code. Record `Applied coding evidence` and advance to `VERIFICATION_AUDITOR` only after the student answers accurately.
- A concept is routine-eligible only when `Student-Mastery.md` records both evidence tracks, a real project file/method in `Evidence source`, and `Routine eligibility: Yes`; explanation, approval, copied code, and agent-generated code are not enough.
- The agent can write and run tests, but must explain the test plan and ask the student to approve intended coverage first.
- Use Vanilla C# MVVM for state and commands: implement `INotifyPropertyChanged` and `ICommand` explicitly; never use MVVM source-generator shortcuts (`[ObservableProperty]`, `[RelayCommand]`, `ObservableObject`). `CommunityToolkit.Maui` UI controls and `WeakReferenceMessenger` (for messaging instead of obsolete `MessagingCenter`) are allowed.
- Prefer `ICommand.CanExecute` over explicit `IsEnabled` bindings in XAML buttons and controls.
- Never use `Page.IsBusy`, synchronous `DisplayAlert`, or legacy `FadeTo`/`ScaleTo`; use ViewModel `IsLoading` + `ActivityIndicator`, `DisplayAlertAsync`, and `*ToAsync` animations.
- In ViewModels, prefer explicit 3-line setters (`if (_field == value) return; _field = value; OnPropertyChanged();`). If `SetProperty(ref _field, value)` is encountered or proposed before `Learning/Student-Mastery.md` records mastery of `ref`, do NOT fail the build. Instead, issue a pedagogical warning to the student, explain the mechanism (`ref` parameter passing and backing field update), and ask the student whether they prefer to keep it or use the explicit 3-line setter. In Custom Views/Controls (`BindableObject`/`ContentView`), this restriction does not apply.
- Verify against official docs at high-friction points: NuGet native packages (SQLite), MAUI platform controls (WebView, Camera, Maps at https://learn.microsoft.com/en-us/dotnet/maui/user-interface/controls/map?view=net-maui-10.0 and Google Maps Android API key setup at https://developers.google.com/maps/documentation/android-sdk/get-api-key?hl=he), Google AI / Gemini .NET SDK (`Google.GenAI` at https://googleapis.github.io/dotnet-genai/), Cloud SDKs (Firebase/Firestore), and runtime crash diagnostics.
- Always write learning documentation (`Learning/MAUI-Learning-Book.md` and `Learning/Guides/*.md`) in **Hebrew** with **English code identifiers**.
- Track 5-unit Bagrut requirements in `Learning/Bagrut-Compliance.md` (`PLANNED` -> `IMPLEMENTED`), remind the student of remaining `PLANNED` items at the end of each slice, and suggest natural opportunities to implement them.
- Never place `// Generated by AI` attribution comments inside `.cs` or `.xaml` files; record all AI/external code and APA bibliography entries in `Learning/AI-And-External-Code-Attribution.md`.
- Run build/tests/validation before declaring `Status: COMPLETE` in `VERIFICATION_AUDITOR`. Never claim `COMPLETE` if a check failed or was not run.

## SQLite Package & Latest-Stable NuGet Rule

- **Always Install Latest Stable NuGet Packages:** Never hardcode stale NuGet version numbers from memory into `.csproj` files. Always install packages via `dotnet add package <PackageId>` (without `--prerelease`) or resolve the latest stable version from NuGet.org (`Validate-Maui-Version.ps1/.sh` enforces latest stable versions and rejects legacy `xunit` v2 in favor of `xunit.v3`; pass `-Fix` to auto-upgrade).
- For unit test projects (`<AppName>.Tests`), always use **`xunit.v3`** (latest stable `>= 4.0.3`, provisioned automatically by `Ensure-Test-Project.ps1/.sh`), never legacy `xunit` v2 (`2.x`).

For SQLite student projects, the only approved data-access stack is:

- `sqlite-net-pcl` (**latest Stable version**, `>= 1.11.285`, `SQLiteAsyncConnection`) for basic CRUD, following https://learn.microsoft.com/en-us/dotnet/maui/data-cloud/database-sqlite?view=net-maui-10.0
- `SQLiteNetExtensions` (and `SQLiteNetExtensions.Async`, **latest Stable version**, `>= 2.1.0`, when using async relationship helpers such as `GetWithChildrenAsync` / `InsertWithChildrenAsync` on `SQLiteAsyncConnection`) added on top of `sqlite-net-pcl` only when one-to-one, one-to-many, or many-to-many relationships are required:
  - https://www.codejourney.net/sqlite-net-extensions-one-to-one-relationships/
  - https://www.codejourney.net/sqlite-net-extensions-one-to-many-relationships/
  - https://www.codejourney.net/sqlite-net-extensions-many-to-many-relationships/

Do not use EF Core SQLite, `Microsoft.Data.Sqlite`, `System.Data.Sqlite`, Dapper, or any alternative SQLite provider/ORM. Keep persistence in Services/Repositories, use async APIs (`SQLiteAsyncConnection`), and never block the UI thread with `.Result` or `.Wait()`.

## Expected Project Structure

```text
<AppName>/           main MAUI app project
<AppName>.Tests/     xUnit test project
.agents/             agent config and skills
Scripts/             validation and learning-book scripts
Learning/            student learning artifacts
Docs/                project documentation
```

## Useful Commands

### Windows (PowerShell)

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
.\Scripts\Generate-Learning-Book-Pdf.ps1
.\Scripts\Validate-Learning-Book.ps1
```

### macOS / Linux (Bash)

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
./Scripts/Generate-Learning-Book-Pdf.sh
./Scripts/Validate-Learning-Book.sh
```

If a script is missing, continue with the closest manual check and state the limitation.

For an HTML/PDF learning book, install `Scripts/Learning-Book-Requirements.txt`, run the generic mockup capture tool, and require `Learning/MAUI-Learning-Book.validation.json` to pass before calling the book publication-ready.

## MAUI DevFlow Runtime Verification & Guardrail Precedence (v1.5.1)

- **Two-Layer TFM-Gated Provisioning & Opt-Out (`Scripts/Ensure-Maui-DevFlow.py` / `.ps1` / `.sh`)**: Installing or updating the skill on a `.NET MAUI` project provisions two layers when the project targets `net10.0` or `net11.0` (skipping `net9.0` and older targets such as `net9.0-android`): (1) Project layer — injects pinned `Microsoft.Maui.DevFlow.Agent` (`0.1.0-preview.14.26531.2`) under `Condition="'$(Configuration)' == 'Debug'"` into `.csproj` and `#if DEBUG` `builder.AddMauiDevFlowAgent();` into `MauiProgram.cs`; and (2) Machine layer — installs or updates the global `.NET MAUI DevFlow CLI` (`dotnet tool install -g Microsoft.Maui.Cli --prerelease`). Opt out of all DevFlow provisioning with `-SkipDevFlow` / `--skip-devflow` (`--no-devflow`), skip global CLI installation with `-SkipCli` / `--skip-cli` when working without global permissions, or remove project injection with `--remove`.
- **Debug-Only Enforcement**: `Scripts/Validate-Maui-ObsoleteApis.ps1/.sh` fails with `[RELEASE LEAK]` if `Microsoft.Maui.DevFlow` is referenced without a strict positive `Debug` condition (blocking `!= 'Debug'`) or if `AddMauiDevFlowAgent()` / `using Microsoft.Maui.DevFlow` appears outside `#if DEBUG` (blocking `#if !DEBUG`), including when Python is absent in `.sh`.
- **Stage 7 (`VERIFICATION_AUDITOR`) Mandatory Visual & PDF Blocking Gate**: It is strictly forbidden to declare `Status: COMPLETE` until one of the two visual pipelines is completed for every screen AND the PDF learning book is compiled (`Learning/MAUI-Learning-Book.pdf` + `Learning/MAUI-Learning-Book.validation.json` verified via `Validate-Learning-Book.ps1/.sh`): (Route A) When `MAUI DevFlow` is installed and actively working on the target platform, run the app, tap the target control by `AutomationId`, verify live binding values from the visual tree, and capture a real screenshot into `Learning/Images/<ScreenName>-live.png`; or (Route B — Mandatory Fallback whenever DevFlow is unavailable) create `Learning/Mockups/<ScreenName>.html`, run `python .\Scripts\Capture-Mockup-Blocks.py` into `Learning/Images/`, embed the images in `Learning/Guides/*.md`, and run `python .\Scripts\Generate-Learning-Book-Pdf.py`.
- **Student Mode Bug Hand-Off**: In `studentCapabilityMode=true`, the agent must NEVER auto-fix UI or binding bugs discovered via `MAUI DevFlow`; it reports the visual-tree readout and screenshot to the student and sets `Status: BLOCKED` or `WAITING_FOR_STUDENT`.
- **Precedence over External Skills**: `maui-k12-baton-workflow` guardrails strictly override any external `dotnet/maui-labs` (`maui ai init`) skills (Vanilla C# MVVM and baton gates are never bypassed).
