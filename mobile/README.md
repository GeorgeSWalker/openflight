# OpenFlight Mobile

A Flutter companion app for the [OpenFlight](../README.md) open-source golf launch monitor. It provides a professional-grade dashboard and 3D ball-flight simulator that connects to the Raspberry Pi over Wi-Fi.

---

## Features

| Feature | Description |
|---|---|
| **Dashboard** | Real-time "big number" tiles — ball speed, club speed, spin, carry, launch angles, smash factor |
| **Dispersion Canvas** | 2D top-down shot landing map with a moveable target flag |
| **Club Picker** | Horizontal scrolling chip strip — sends `UpdateConfig` RPC back to the Pi |
| **Simulator Mode** | Unity 3D ball-flight scene embedded via `flutter_unity_widget` |
| **Connection Heartbeat** | Animated indicator showing gRPC link health and round-trip latency |
| **Mock Mode** | Full UI demo without any hardware — works out of the box |

---

## Architecture

```
┌─────────────────────────────────────┐
│          Flutter Mobile App          │
│                                      │
│  HomeScreen                          │
│    ├── DashboardScreen               │
│    │     ├── StatTiles (BlocBuilder) │
│    │     └── DispersionCanvas        │
│    └── SimulatorScreen               │
│          └── UnityWidget (3D flight) │
│                                      │
│  State layer (flutter_bloc)          │
│    ├── ConnectionCubit               │
│    ├── ShotCubit                     │
│    ├── ClubCubit                     │
│    ├── TargetDistanceCubit           │
│    └── AppModeCubit                  │
│                                      │
│  LaunchMonitorClient (gRPC)          │
└───────────────┬─────────────────────┘
                │ gRPC / Wi-Fi
                │ port 50051
┌───────────────▼─────────────────────┐
│     Raspberry Pi — gRPC Server       │
│  (⚠️  not yet implemented — see below) │
└──────────────────────────────────────┘
```

### Bloc → UI data flow

```
LaunchMonitorClient.shots  ──►  ShotCubit  ──►  BlocBuilder  ──►  StatTiles
                                           ──►  BlocListener ──►  Unity postMessage
LaunchMonitorClient.connectionState ──► ConnectionCubit ──► ConnectionIndicator
ClubPicker tap ──► ClubCubit.select() ──► gRPC UpdateConfig RPC ──► Pi
```

### Protobuf contract (`proto/openflight.proto`)

```protobuf
service LaunchMonitor {
  rpc StreamShots  (Empty)      returns (stream ShotData);   // Pi → app
  rpc UpdateConfig (UserConfig) returns (ConfigResponse);    // app → Pi
  rpc Ping         (Empty)      returns (PingResponse);      // heartbeat
}
```

---

## ⚠️  Backend gRPC Status

**The Pi backend has NOT yet been updated to serve gRPC.** The existing backend (`src/openflight/server.py`) currently uses **Flask + WebSockets** (Flask-SocketIO on port 8080).

The mobile app ships with a `MockLaunchMonitorClient` that emits realistic shot data on a timer — you can develop and demo the full UI without hardware.

To connect to real hardware you will need to add a gRPC server to the Pi backend that implements the three RPCs above. The Protobuf definition is at `mobile/proto/openflight.proto`.

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Flutter SDK | ≥ 3.3 | [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install) |
| Dart SDK | bundled with Flutter | — |
| Android Studio **or** Xcode | latest stable | For device emulation / deployment |
| `protoc` + `protoc-gen-dart` | any | Only needed to regenerate proto stubs |

> **protoc setup (optional — only needed if you change the `.proto` file)**
> ```bash
> dart pub global activate protoc_plugin
> brew install protobuf   # macOS
> # or: sudo apt install protobuf-compiler
> bash mobile/scripts/generate_proto.sh
> ```

---

## Getting Started

### 1. Install dependencies

```bash
cd mobile
flutter pub get
```

### 2. Run in mock mode (no hardware needed)

```bash
flutter run
```

The app auto-connects to `MockLaunchMonitorClient`, which fires realistic shot data every 4 seconds. All screens, animations, and the dispersion canvas work fully.

### 3. Run against real hardware

1. Ensure the Pi gRPC server is running (see [Backend gRPC Status](#%EF%B8%8F-backend-grpc-status)).
2. Find the Pi's IP address on your Wi-Fi network (e.g. `192.168.1.100`).
3. Launch the app, tap the **settings icon** in the app bar.
4. Enter the Pi IP and port `50051`, then tap **Connect**.

To hard-code a default IP at build time:

```bash
flutter run --dart-define=PI_HOST=192.168.1.100 --dart-define=PI_PORT=50051
```

### 4. Start the existing WebSocket backend (for the web UI)

```bash
# From the repo root
uv run python -m openflight.server --mock          # mock mode, no radar
uv run python -m openflight.server --mode streaming # with radar on /dev/ttyACM0
```

Web UI is then available at `http://localhost:8080`.

---

## Running Tests

```bash
cd mobile
flutter test
```

Test coverage:

| File | What it tests |
|---|---|
| `test/bloc/connection_cubit_test.dart` | gRPC lifecycle states (connecting → connected → disconnected) |
| `test/bloc/shot_cubit_test.dart` | Shot accumulation, 20-shot ring buffer cap, `clearHistory()` |
| `test/bloc/club_cubit_test.dart` | Club selection emissions, `UpdateConfig` RPC |
| `test/services/launch_monitor_client_test.dart` | `MockLaunchMonitorClient` stream behaviour |
| `test/ui/widgets/stat_tile_test.dart` | StatTile rendering, highlighted border |

---

## Project Structure

```
mobile/
├── proto/
│   └── openflight.proto          # Protobuf contract (source of truth)
├── scripts/
│   └── generate_proto.sh         # Regenerate Dart stubs from .proto
├── lib/
│   ├── main.dart                 # Entry point
│   ├── app.dart                  # RepositoryProvider + MultiBlocProvider root
│   ├── proto/
│   │   ├── openflight.pb.dart    # Generated protobuf messages
│   │   └── openflight.pbgrpc.dart# Generated gRPC client stub
│   ├── core/
│   │   ├── constants/theme.dart  # Dark theme, AppColors, AppSpacing
│   │   └── models/               # ShotDataModel, ConnectionStateModel
│   ├── services/
│   │   └── launch_monitor_client.dart  # Real + Mock gRPC clients
│   ├── bloc/
│   │   ├── connection/           # ConnectionCubit
│   │   ├── shot/                 # ShotCubit + ShotState
│   │   ├── club/                 # ClubCubit
│   │   ├── target_distance/      # TargetDistanceCubit
│   │   └── app_mode/             # AppModeCubit
│   └── ui/
│       ├── screens/
│       │   ├── home_screen.dart      # Shell scaffold
│       │   ├── dashboard_screen.dart # Stats + dispersion
│       │   └── simulator_screen.dart # Unity 3D view
│       └── widgets/
│           ├── connection_indicator.dart
│           ├── stat_tile.dart
│           ├── dispersion_canvas.dart
│           ├── club_picker.dart
│           └── waiting_for_swing.dart
└── test/
    ├── bloc/
    ├── services/
    └── ui/widgets/
```

---

## Unity Simulator Setup

The simulator screen embeds a Unity project via `flutter_unity_widget`. The Unity project is not included in this repository. To wire it up:

1. Create a Unity project (URP, Unity 2022 LTS recommended).
2. Follow the [flutter_unity_widget setup guide](https://pub.dev/packages/flutter_unity_widget).
3. Add a `GameObject` named **`BallPhysicsManager`** with a C# component that implements:
   ```csharp
   public void OnShotData(string json)
   {
       var shot = JsonUtility.FromJson<ShotData>(json);
       // Launch ball physics simulation using shot data
   }
   ```
4. Export the Unity project into `mobile/unity/` following the plugin's export instructions.

---

## Design Tokens

| Token | Value | Usage |
|---|---|---|
| `AppColors.background` | `#121212` | Scaffold background |
| `AppColors.surface` | `#1E1E1E` | Cards, app bar |
| `AppColors.accent` | `#00E676` | OpenFlight Green — active states, highlights |
| `AppColors.onSurfaceMuted` | `#9E9E9E` | Labels, secondary text |
| Font | Inter (Google Fonts) | All text; tabular figures on numerics |

---

## Troubleshooting

**"No Signal" in the connection indicator**
- The app defaults to `MockLaunchMonitorClient` — tap the settings icon and connect to a real IP only when the Pi gRPC server is running.

**`flutter pub get` fails on `flutter_unity_widget`**
- Run `flutter config --enable-android` or `--enable-ios` first, then retry.

**Proto stubs out of date**
- Run `bash scripts/generate_proto.sh` from the `mobile/` directory after installing `protoc` and `protoc-gen-dart`.
