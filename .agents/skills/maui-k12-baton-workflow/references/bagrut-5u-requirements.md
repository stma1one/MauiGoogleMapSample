# Ministry of Education 5-Unit Capstone Requirements (.NET MAUI — Rubric 883589)

Read this reference during `PLANNING_COACH`, `PLAN_CONFIRMATION`, `CODE_LEARNING_REVIEWER`, and `VERIFICATION_AUDITOR` to ensure the student's .NET MAUI project meets all mandatory and elective requirements for the 5-unit Software Engineering Smartphone Programming capstone (סמל 883589 — חלופת טלפונים חכמים, 5 יח"ל).

Track the project's status in `Learning/Bagrut-Compliance.md` (`PLANNED` during development, `IMPLEMENTED` with concrete file paths once coded) and log all AI/external code in `Learning/AI-And-External-Code-Attribution.md`.

---

## 1. Threshold Requirements (דרישות סף חובה 1–4)

Every project **must** satisfy all four threshold requirements or it is disqualified (grade 0):

1. **Requirement 1 — Working Smartphone Application:** Runs on Android (and target platforms) during examination without crashes.
2. **Requirement 2 — Non-Trivial Domain Logic:** Includes meaningful algorithmic/business logic beyond basic CRUD screens.
3. **Requirement 3 — Multi-Screen Interactive GUI & UX:** Uses multiple screens/views (`ContentPage` / `ContentView`) with clear navigation, usability, accessibility, and human-factors design.
4. **Requirement 4 — Events & Runtime Permissions:** Handles UI control events, listeners, lifecycle/system events (e.g., connectivity changes, lifecycle hooks), and runtime permissions (`Permissions.RequestAsync<T>()`) appropriate to the app.

---

## 2. Section 5 — Artificial Intelligence (חובה לממש לפחות נתיב AI אחד מתוך ה-4; ניתן לשלב יותר מאחד)

The student must implement **at least ONE** (`>= 1`) of the following 4 AI paths (implementing one path satisfies the mandatory Section 5 threshold, and there is no restriction against implementing more than one AI path to enrich the project).
*Rule:* Implementing Section 5 AI also counts as **1 of the required topics in Section 6**.
*Google AI / Gemini Single Source of Truth:* When implementing Section 5 AI against Google Gemini in .NET MAUI, use the official **`Google.GenAI`** .NET SDK (**latest Stable version**, `>= 2.2.0`) and follow its official documentation at **https://googleapis.github.io/dotnet-genai/** (`Google.GenAI.Client`, `client.Models.GenerateContentAsync(...)`, and `GenerateContentConfig`).
  - **Mobile Android Checklist for `Google.GenAI`:**
    1. Initialize `new Client(apiKey: apiKey)` with a Gemini Developer API key (never `vertexai: true`, which requires server ADC unavailable on Android, and never hardcode a real `AIzaSy...` key in committed source files).
    2. Confirm `<uses-permission android:name="android.permission.INTERNET" />` is present in `Platforms/Android/AndroidManifest.xml`.
    3. Make the AI Service unit-testable in `xunit.v3` by extracting an interface (`IGeminiAiService`) for ViewModel fake testing and a pure `ParseStructuredResponse(string json)` method for testing JSON schema deserialization offline.

| Path ID | Official Path Name | .NET MAUI Implementation Guidance |
| :--- | :--- | :--- |
| **`AI-1`** | **LLM API Integration with Structured Output (` אינטגרציית מודל שפה LLM API`)** | **Recommended for .NET MAUI.** For Google Gemini, use the official `Google.GenAI` SDK (https://googleapis.github.io/dotnet-genai/) in a dedicated `Service` class (or `HttpClient` for other providers). Must define a strict output schema (`GenerateContentConfig` with `ResponseMimeType = "application/json"` and `ResponseSchema` / `JSON Schema`) and deserialize the response (`JsonSerializer.Deserialize<T>()`) into strongly-typed C# models integrated into app logic or saved to the database (displaying raw free text alone does **not** qualify). |
| **`AI-2`** | **Pre-Trained Models (`שילוב מודלים מוכנים מראש`)** | Non-generative analysis/recognition (OCR, object/face detection, audio analysis, classification) without training a model. In .NET MAUI, prefer multimodal `Google.GenAI` vision/audio analysis (https://googleapis.github.io/dotnet-genai/), cloud vision/speech REST APIs, or stable cross-platform plugins (`Plugin.Maui.OCR`) in a `Service` class, and feed the structured output directly into app state/database/triggers. |
| **`AI-3`** | **Runtime AI Agent (`סוכן בינה מלאכותית AI Agent`)** | **Recommended for .NET MAUI.** An intelligent runtime agent powered by an LLM API (such as `Google.GenAI` with `Tools` / Function Calling per https://googleapis.github.io/dotnet-genai/) that accepts natural-language user input and invokes internal C# methods/services (Function/Tool Calling, dynamic scheduling, route/move calculation, or multi-step decision making). |
| **`AI-4`** | **Custom ML Pipeline (`אימון מודל מותאם אישית והטמעתו`)** | End-to-end ML pipeline: dataset preparation (e.g., CSV), algorithmic training code (`ML.NET` or Python `scikit-learn` / `TensorFlow` exported to ONNX or hosted via a dedicated inference endpoint), and runtime inference integrated into the MAUI app. (No-code tools like Teachable Machine without data-processing code are **not** accepted). |

---

## 3. Section 6 — Core System & MAUI Topics (חובה לפחות 2 נושאים; נתיב ה-AI מסעיף 5 נספר כנושא 1)

The project must implement **at least 2 topics** from Section 6 (since Section 5 AI counts as 1 topic, at least 1 additional topic—and in standard MAUI apps several—will be satisfied):

* **`6.1`** **Background Scheduling (`Job Scheduler / Work Manager`):** Scheduled background work or Android `WorkManager` / `ForegroundService`.
* **`6.3`** **Network Data Fetching (`הורדת נתוני מידע מהרשת`):** Downloading structured data (JSON/XML via `HttpClient`, not just static images/music) and using it in app logic (e.g., exchange rates, nearby businesses, live feeds).
* **`6.4`** **Meaningful Service Layer / Background Service (`כתיבת מחלקת Service משמעותית`):** Domain/application services with substantial logic injected via DI (or a platform `ForegroundService`). Simple media playback does not count.
* **`6.5`** **Relational Database with Complex Relationships & Advanced Queries (`מסד נתונים עם יחסים מורכבים`):** 1:N or M:N relationships using `sqlite-net-pcl` + `SQLiteNetExtensions.Async` (or explicit foreign-key joins/aggregations `JOIN`, `GROUP BY`).
* **`6.7`** **Multi-View Swipe / Pager (`CarouselView` / `TabbedPage` + `ContentView`):** Categorized views, swipeable galleries, or multi-step wizards.
* **`6.8`** **MAUI Async & Threading (`Task` / `MainThread` / `Dispatcher`):** Non-blocking async operations with `async/await` and `MainThread.BeginInvokeOnMainThread`.
* **`6.9`** **MAUI Object Events (`event` / `Invoke` / `WeakReferenceMessenger`):** Raising and subscribing to custom events or decoupled messages.
* **`6.10`** **MAUI DataBinding, `IValueConverter`, & Compiled Bindings (`x:DataType`):** Full data binding and value converters in XAML.
* **`6.11`** **MAUI `ObservableCollection<T>` + `CollectionView`:** Dynamic reactive lists with templates.
* **`6.12`** **Comprehensive `MVVM` Architecture:** Strict separation of `Model`, `View`, `ViewModel`, and `Service` across the entire project.

*(Note: Android-specific `ContentProvider` is omitted for .NET MAUI projects).*

---

## 4. Section 7 — Database Persistence (חובה כתיבה וקריאה בבסיס נתונים)

The project **must** read and write data in a real database:
- **Option `DB-Local`:** Local **`SQLite`** database (`sqlite-net-pcl` with `SQLiteAsyncConnection`, plus `SQLiteNetExtensions` / `SQLiteNetExtensions.Async` when relationships are used).
- **Option `DB-Remote-Sync`:** Remote database (**`Firebase Firestore`**, **`Firebase Realtime Database`**, or **`MySQL`** via backend) with both read/write and **real-time/synchronous data updates**.
  - **Important Rubric Rule:** Implementing `DB-Remote-Sync` automatically counts as **2 topics in Section 10**!
- **Disallowed as sole database:** `Preferences` (`SharedPreferences`), plain text files, or local JSON/XML files do **not** satisfy Section 7.

---

## 5. Section 8 — Advanced Topics Combination Rule (חובה לעמוד באפשרות 1 או באפשרות 2)

The student must satisfy **one** of these two combinations from Sections 9 and 10:
- **Track 1 (`אפשרות 1`):** At least **3 topics from Section 9**.
- **Track 2 (`אפשרות 2`):** At least **2 topics from Section 9** AND at least **2 topics from Section 10** *(remember: a remote synchronized DB in Section 7 automatically provides 2 topics for Section 10)*.

### Section 9 Topics (Mapped to .NET MAUI):
* **`9.1` / `9.3`** **Custom 2D Graphics (`GraphicsView` + `IDrawable` / `ICanvas`):** Custom drawing, game boards, interactive charts, or visual canvases.
* **`9.2`** **Scheduled Notifications (`AlarmManager + Notification`):** Local scheduled notifications (`Plugin.LocalNotification` or platform notification service).
* **`9.4`** **Maps & Location Data (`Microsoft.Maui.Controls.Maps.Map`):** Interactive map displaying pins, routes, or location-aware data.
  - **Official .NET MAUI Map Reference:** https://learn.microsoft.com/en-us/dotnet/maui/user-interface/controls/map?view=net-maui-10.0 (`Microsoft.Maui.Controls.Maps` NuGet, `.UseMauiMaps()` in `MauiProgram.cs`, `xmlns:maps="http://schemas.microsoft.com/dotnet/2021/maui/maps"`).
  - **Google Maps Android API Key Setup (Hebrew Guide for Students):** https://developers.google.com/maps/documentation/android-sdk/get-api-key?hl=he (configure `<meta-data android:name="com.google.android.geo.API_KEY" ... />` and `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` in `Platforms/Android/AndroidManifest.xml`).
* **`9.5`** **Continuous Location / Motion Listeners (`מאזיני מיקום / תנועה`):** Active location tracking (`Geolocation.StartListeningForegroundAsync`) or motion listeners (`Accelerometer`, `Gyroscope`, `Compass`).
* **`9.6`** **Bluetooth (`BLE`):** Communicating with Bluetooth devices (requires physical device testing).
* **`9.7`** **NFC:** Reading/writing NFC tags (requires physical device testing).
* **`9.8`** **Inter-Device / Network Communication (`תקשורת בין מחשבים`):** Direct socket/WebSocket/SignalR communication between clients.
* **`9.9`** **Custom Backend Server API (`פיתוח API בצד שרת`):** Student-authored server API (e.g., ASP.NET Core Web API, Python FastAPI, Node.js) consumed by the MAUI app.
* **`9.10`** **Complex Algorithmic / Game Brain Engine (`כתיבת מנוע מוח / מודל אלגוריתמי מורכב`):** Non-random game AI (e.g., Minimax, heuristics), graph routing/navigation, scheduling/optimization engine in C#.
* **`9.11`** **Emerging Technology (`טכנולוגיה חדשה`):** Advanced media/image/voice processing or novel hardware/cloud integration.
* **`9.12`** **Real-Time Multi-User / Multiplayer Application (`אפליקציית רב-משתתפים`):** Simultaneous multi-user interaction where one user's action updates other users' state in real time or resolves shared-resource conflicts (e.g., live multiplayer game, real-time seat/appointment booking).

### Section 10 Topics (Mapped to .NET MAUI):
*(Note: Legacy Android `AsyncTask` and `ContentProvider` are omitted for .NET MAUI).*
* **`10.1`** **Messaging / Connectivity Broadcasts (`WeakReferenceMessenger` / `ConnectivityChanged`):** Decoupled messaging or system state broadcast listeners.
* **`10.2`** **User Preferences (`Preferences.Default`):** Storing user settings/preferences via `Microsoft.Maui.Storage.Preferences`.
* **`10.3`** **Camera & Photo Gallery (`MediaPicker.Default`):** Capturing photos or picking images from the device gallery.
* **`10.5`** **Microphone (`Audio Recorder`):** Recording voice/audio input in the app.
* **`10.6`** **GPS Location (`Geolocation.Default.GetLocationAsync`):** Retrieving current device coordinates.
* **`10.7`** **Screen Result Callback (`Shell IQueryAttributable` / Modal Result):** Passing structured result data back from a child/modal page to the caller.
* **`10.8`** **Countdown Timer (`IDispatcherTimer` / `PeriodicTimer`):** Live countdown timer driving UI state or game/task deadlines.
* **`10.9`** **Text-To-Speech (`TextToSpeech.Default.SpeakAsync`):** Speaking text aloud using `Microsoft.Maui.Media`.
* **`10.10`** **Speech-To-Text (`SpeechToText` via `CommunityToolkit.Maui.Media`):** Converting spoken user audio into text.
* **`10.11`** **Device Sensors (`Sensors`):** Using `Accelerometer`, `Barometer`, `Compass`, `Gyroscope`, `Magnetometer`, or `OrientationSensor`.
* **`10.12`** **Calendar with Filter Logic (`לוח שנה עם לוגיקת סינון`):** Date/calendar scheduling view with multi-criteria filtering logic in the ViewModel.

---

## 6. Proactive Pedagogical Reminders & Opportunity Suggestions

1. **During `PLANNING_COACH` & `PLAN_CONFIRMATION`:**
   - Check `Learning/Bagrut-Compliance.md`. Ensure the student has selected a valid 5-unit path (`PLANNED` or `IMPLEMENTED`, including at least one AI path in Section 5).
   - **Approve Compliant Plan + Suggest Optional Expansion**: When the student's plan meets the mandatory compliance thresholds, **approve** the plan and proactively offer optional enrichment ideas (such as combining a second complementary AI path or adding an extra Section 9/10 component that fits the app domain).
   - **Never Claim Script Output Proves Implementation Correctness**: `Validate-Bagrut-Compliance` only checks self-reported table declarations (`DECLARATION_CHECK_OK`); never present its output as proof that the C# implementation itself is functionally valid.
   - If the feature being planned naturally fits an unfulfilled rubric item, proactively suggest it! Examples:
     - *Profile or Item creation screen* -> Suggest `MediaPicker` (`10.3`), `Preferences` (`10.2`), or `TextToSpeech` (`10.9`).
     - *Dashboard or Statistics screen* -> Suggest a custom chart using `GraphicsView` + `IDrawable` (`9.3`).
     - *Task, Event, or Workout screen* -> Suggest a live `IDispatcherTimer` countdown (`10.8`), scheduled notification (`9.2`), or calendar filter (`10.12`).
     - *Location or Delivery screen* -> Suggest `Geolocation` (`10.6`) + `Map` (`9.4`).
2. **At the End of `VERIFICATION_AUDITOR` (End-of-Slice Reminder):**
   - After verifying the slice, briefly remind the student of their current `Learning/Bagrut-Compliance.md` progress (how many items are `IMPLEMENTED` vs. still `PLANNED`) and suggest 1-2 natural next features that will turn remaining `PLANNED` items into `IMPLEMENTED`.

---

## 7. Separate AI & External Code Attribution Rule (No AI Comments in Code!)

- **Never** write `// Generated by AI`, `// Written by Claude/ChatGPT/Gemini`, or bibliography numbers `[1]` inside `.cs` or `.xaml` source files. Source code comments must remain clean, professional XML/code documentation explaining *what* the code does and *why*.
- Instead, record every agent-scaffolded, AI-assisted, or externally sourced code block in **`Learning/AI-And-External-Code-Attribution.md`**, including:
  - exact file, class, and method name;
  - what the agent/source provided vs. what the student implemented or modified;
  - key talking points so the student can explain the code and their modifications to the oral examiner (worth 25% in Part B of the rubric); and
  - an APA-formatted bibliography entry when external/AI code was imported.
