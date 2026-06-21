import {
  pickProvider,
  type ModelProvider,
  type PlatformName
} from "./model_provider_router";
import { selectOpeningCard, type LaunchContext, type OpeningCard } from "./opening_engine";

export type OpeningBootstrapDeps = {
  platform: PlatformName;
  userId: string;
  sessionId: string;
  cards: OpeningCard[];
  userProfile: any;
  history: any[];
  tags: any[];
  context: LaunchContext;
  localModel?: ModelProvider;
  dsApi?: ModelProvider;
};

export type OpeningBootstrapResult = {
  sessionId: string;
  platform: PlatformName;
  provider: "local_model" | "ds_api";
  openingCard: OpeningCard | null;
  reason: string;
};

export async function bootstrapOpeningExperience(
  deps: OpeningBootstrapDeps
): Promise<OpeningBootstrapResult> {
  const providerSelection = pickProvider(deps.platform, {
    localModel: deps.localModel,
    dsApi: deps.dsApi
  });

  const selection = selectOpeningCard({
    user: deps.userProfile,
    cards: deps.cards,
    history: deps.history,
    tags: deps.tags,
    context: deps.context,
    sessionId: deps.sessionId
  });

  return {
    sessionId: deps.sessionId,
    platform: deps.platform,
    provider: providerSelection.providerName,
    openingCard: selection.card,
    reason: selection.reason
  };
}
