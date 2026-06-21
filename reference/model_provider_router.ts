export type PlatformName = "windows" | "android" | "web";
export type ProviderName = "local_model" | "ds_api";

export type ModelRequest = {
  prompt: string;
  systemPrompt?: string;
  temperature?: number;
  maxTokens?: number;
};

export type ModelResponse = {
  text: string;
  provider: ProviderName;
  raw?: unknown;
};

export interface ModelProvider {
  generate(request: ModelRequest): Promise<ModelResponse>;
}

export type PlatformCapabilities = {
  platform: PlatformName;
  supportsLocalModel: boolean;
  supportsDsApi: boolean;
  defaultProvider: ProviderName;
};

export function getPlatformCapabilities(platform: PlatformName): PlatformCapabilities {
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

export type ProviderRegistry = {
  localModel?: ModelProvider;
  dsApi?: ModelProvider;
};

export function pickProvider(
  platform: PlatformName,
  registry: ProviderRegistry
): { providerName: ProviderName; provider: ModelProvider } {
  const capabilities = getPlatformCapabilities(platform);

  if (capabilities.defaultProvider === "local_model" && registry.localModel) {
    return { providerName: "local_model", provider: registry.localModel };
  }

  if (capabilities.defaultProvider === "ds_api" && registry.dsApi) {
    return { providerName: "ds_api", provider: registry.dsApi };
  }

  if (registry.localModel) {
    return { providerName: "local_model", provider: registry.localModel };
  }

  if (registry.dsApi) {
    return { providerName: "ds_api", provider: registry.dsApi };
  }

  throw new Error(`No compatible model provider registered for platform: ${platform}`);
}
