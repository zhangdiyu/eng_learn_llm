# Platform Integration Plan for Win, Web, and Android

## Goal

Integrate the Opening Experience Engine into the existing app engine and make platform-specific model routing behave as follows:

- `Windows`: default to local model execution
- `Android`: default to local model execution
- `Web`: use DS API

This document assumes the app already has a shared engine layer or can be reorganized to have one.

## 1. Recommended Architecture

Use three layers:

### Shared Core

Contains logic that should behave the same across platforms:

- opening card selection
- user memory
- question history
- tag inference
- event tracking contract
- model provider abstraction

### Platform Adapter Layer

Contains platform-specific implementations:

- local storage path
- local model runner integration
- DS API client
- build flags
- runtime environment detection

### UI Layer

Renders startup card flow and captures user actions.

## 2. Shared Modules to Introduce

Recommended shared modules:

- `opening_engine`
- `opening_repository`
- `opening_history_repository`
- `user_profile_repository`
- `model_provider`
- `platform_capabilities`
- `opening_bootstrap_service`

## 3. Model Routing Rules

### Windows

Default model provider:

- `local_model`

Fallback:

- optional remote provider if local is unavailable

### Android

Default model provider:

- `local_model`

Fallback:

- optional remote provider if local inference is unsupported on the device

### Web

Default model provider:

- `ds_api`

Fallback:

- none for MVP unless explicitly required

## 4. Provider Abstraction

Recommended interface:

```ts
type ModelRequest = {
  prompt: string;
  systemPrompt?: string;
  temperature?: number;
  maxTokens?: number;
};

type ModelResponse = {
  text: string;
  provider: "local_model" | "ds_api";
  raw?: unknown;
};

interface ModelProvider {
  generate(request: ModelRequest): Promise<ModelResponse>;
}
```

## 5. Platform Capabilities Contract

```ts
type PlatformName = "windows" | "android" | "web";

type PlatformCapabilities = {
  platform: PlatformName;
  supportsLocalModel: boolean;
  supportsDsApi: boolean;
  defaultProvider: "local_model" | "ds_api";
};
```

## 6. Routing Logic

```ts
function getPlatformCapabilities(platform: PlatformName): PlatformCapabilities {
  switch (platform) {
    case "windows":
      return {
        platform,
        supportsLocalModel: true,
        supportsDsApi: true,
        defaultProvider: "local_model"
      };
    case "android":
      return {
        platform,
        supportsLocalModel: true,
        supportsDsApi: true,
        defaultProvider: "local_model"
      };
    case "web":
      return {
        platform,
        supportsLocalModel: false,
        supportsDsApi: true,
        defaultProvider: "ds_api"
      };
  }
}
```

## 7. Opening Engine Bootstrap Flow

At app startup:

1. detect platform
2. load platform capabilities
3. initialize repositories
4. initialize model provider
5. initialize opening engine
6. request opening card
7. render opening experience
8. persist user interaction

## 8. Windows Integration

### Build Target Expectations

- desktop executable
- local storage via SQLite
- local model available by default

### Required Integration Points

- app startup hook
- local model runner service
- local database initialization
- opening card UI entry

### Recommended Local Model Integration

Expose a service:

```ts
interface LocalModelRunner {
  isAvailable(): Promise<boolean>;
  generate(request: ModelRequest): Promise<ModelResponse>;
}
```

If the local model is unavailable:

- either show a setup state
- or fallback to DS API if allowed by product settings

## 9. Android Integration

### Build Target Expectations

- APK build
- persistent local storage
- local model default

### Required Integration Points

- application startup or first screen bootstrap
- Android-compatible local model runtime
- local SQLite or equivalent
- lifecycle-safe event writes

### Android Notes

Keep local inference lightweight for MVP:

- short prompts
- bounded token outputs
- explicit timeout

If model size is too large for some devices, the app should:

- detect incompatibility
- degrade gracefully
- surface a non-breaking fallback path

## 10. Web Integration

### Build Target Expectations

- browser build
- DS API as default provider
- no local model dependency

### Required Integration Points

- web app startup entry
- DS API client
- browser-safe storage
- opening card UI entry

### Web Storage

For MVP:

- use browser storage for lightweight state
- or use a backend endpoint if the app already has one

For stronger product consistency:

- sync opening history server-side

## 11. Data Storage Recommendation by Platform

### Windows

- SQLite

### Android

- SQLite or platform-equivalent embedded DB

### Web

- remote persistence preferred
- local browser storage acceptable for MVP if no backend exists

## 12. Shared Startup Contract

The UI layer should call a single bootstrap method:

```ts
type OpeningBootstrapResult = {
  platform: "windows" | "android" | "web";
  provider: "local_model" | "ds_api";
  openingCard: unknown | null;
};

interface OpeningBootstrapService {
  start(userId: string): Promise<OpeningBootstrapResult>;
}
```

This keeps platform differences out of most UI code.

## 13. Build Outputs Required

To meet the request, final delivery should prove:

- Windows build succeeds
- Web build succeeds
- Android APK build succeeds
- Windows defaults to local model
- Android defaults to local model
- Web defaults to DS API

## 14. What Must Be Located in the Existing Project

To wire this into the real engine, the following project files or modules are still required:

- app entry file for `web`
- app entry file for `windows`
- app entry file for `android`
- current model inference service or engine service
- current storage layer

Once those are known, the integration can be done directly rather than through a parallel implementation.
