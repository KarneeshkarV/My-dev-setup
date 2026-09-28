import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "openai-auto-continue";
const CONTINUE_PROMPT = "Continue the work from where you stopped. Check the current state before making changes, then finish the user's task and verify it.";
const RETRY_DELAY_MS = 30 * 60_000;

type Timeout = ReturnType<typeof setTimeout>;
type RetryReason = "temporary server error" | "temporary usage limit";

interface ProviderResponse {
	status: number;
}

interface PendingContinuation {
	provider: string;
	modelId: string;
	retryAt: number;
	attempt: number;
	reason: RetryReason;
}

function isSupportedProvider(provider: string | undefined): boolean {
	return provider === "openai" || provider === "openai-codex" || provider === "9router-cx";
}

/** Identify only provider errors that can recover without a credential or billing change. */
export function classifyProviderRetry(
	message: Pick<AssistantMessage, "stopReason" | "errorMessage">,
	status?: number,
): RetryReason | undefined {
	if (message.stopReason !== "error") return undefined;
	const error = message.errorMessage ?? "";
	const temporaryLimit = /(?:usage[_ -]?limit|rate[_ -]?limit|quota|limit reached|too many requests|resource_exhausted|try again|retry after|resets? (?:at|in))/i.test(error);
	const hardFailure = /(?:invalid[_ -]?(?:api[_ -]?)?key|invalid[_ -]?token|unauthorized|permission denied|insufficient[_ -]?quota|billing|payment required|no remaining credits|out of (?:budget|credits))/i.test(error);

	if (status === 401 || status === 402 || hardFailure) return undefined;
	if (status === 403) return temporaryLimit ? "temporary usage limit" : undefined;
	if (status === 429 || temporaryLimit) return "temporary usage limit";
	if (status === 500 || status === 502 || status === 503 || status === 504 || status === 529 || /(?:service unavailable|overload|temporarily unavailable|gateway timeout|internal server error|\b(?:500|502|503|504|529)\b)/i.test(error)) {
		return "temporary server error";
	}
	return undefined;
}

export default function openAIAutoContinue(pi: ExtensionAPI) {
	let timer: Timeout | undefined;
	let pending: PendingContinuation | undefined;
	let response: ProviderResponse | undefined;
	let lastFailure: RetryReason | undefined;
	let attempts = 0;

	function clearPending(ctx?: ExtensionContext): void {
		if (timer) clearTimeout(timer);
		timer = undefined;
		pending = undefined;
		response = undefined;
		lastFailure = undefined;
		attempts = 0;
		ctx?.ui.setStatus(STATUS_KEY, undefined);
	}

	pi.on("before_provider_request", () => {
		response = undefined;
	});

	pi.on("after_provider_response", (event, ctx) => {
		if (isSupportedProvider(ctx.model?.provider)) response = { status: event.status };
	});

	pi.on("message_end", (event, ctx) => {
		if (event.message.role !== "assistant" || !isSupportedProvider(ctx.model?.provider)) return;
		const message = event.message as AssistantMessage;
		lastFailure = classifyProviderRetry(message, response?.status);
		response = undefined;
		if (!lastFailure) clearPending(ctx);
	});

	// Pi's built-in retries and compaction finish before this event. Never start our timer on an intermediate failure.
	pi.on("agent_settled", (_event, ctx) => {
		if (!lastFailure || !isSupportedProvider(ctx.model?.provider) || !ctx.model) return;
		if (timer) clearTimeout(timer);
		attempts += 1;
		pending = {
			provider: ctx.model.provider,
			modelId: ctx.model.id,
			retryAt: Date.now() + RETRY_DELAY_MS,
			attempt: attempts,
			reason: lastFailure,
		};
		lastFailure = undefined;
		const scheduled = pending;
		ctx.ui.setStatus(STATUS_KEY, `Retry ${scheduled.attempt} at ${new Date(scheduled.retryAt).toLocaleString()}`);
		ctx.ui.notify(`${scheduled.provider} ${scheduled.reason}. Retry ${scheduled.attempt} in 30 minutes.`, "warning");
		timer = setTimeout(() => {
			timer = undefined;
			if (pending !== scheduled) return;
			if (ctx.model?.provider !== scheduled.provider || ctx.model.id !== scheduled.modelId) {
				clearPending(ctx);
				return;
			}
			pending = undefined;
			ctx.ui.setStatus(STATUS_KEY, undefined);
			pi.sendUserMessage(CONTINUE_PROMPT);
		}, RETRY_DELAY_MS);
	});

	pi.on("input", (event, ctx) => {
		if (pending && event.source !== "extension") clearPending(ctx);
	});
	pi.on("model_select", (_event, ctx) => {
		if (pending && (ctx.model?.provider !== pending.provider || ctx.model.id !== pending.modelId)) clearPending(ctx);
	});
	pi.on("session_start", (_event, ctx) => clearPending(ctx));
	pi.on("session_tree", (_event, ctx) => clearPending(ctx));
	pi.on("session_shutdown", () => clearPending());

	pi.registerCommand("auto-continue-status", {
		description: "Show a pending OpenAI or 9router automatic retry",
		handler: async (_args, ctx) => {
			ctx.ui.notify(
				pending ? `${pending.provider} ${pending.reason}: retry ${pending.attempt} at ${new Date(pending.retryAt).toLocaleString()}.` : "No automatic retry is pending.",
				"info",
			);
		},
	});
	pi.registerCommand("auto-continue-cancel", {
		description: "Cancel a pending OpenAI or 9router automatic retry",
		handler: async (_args, ctx) => {
			if (!pending) {
				ctx.ui.notify("No automatic retry is pending.", "info");
				return;
			}
			clearPending(ctx);
			ctx.ui.notify("Automatic retry cancelled.", "info");
		},
	});
}
