import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

/**
 * Registers the OpenAI-compatible Qwen3-Coder-Next AWQ HTTP endpoint as a pi
 * provider.
 *
 * The endpoint is expected to expose /v1/chat/completions, so the provider base
 * URL should include /v1. No Authorization header is sent by default; pi
 * requires an apiKey for custom models, so a placeholder key is provided with
 * authHeader disabled.
 *
 * Overridable via env:
 * - QWEN_NEXT_AWQ_HTTP_BASE_URL
 * - QWEN_NEXT_AWQ_HTTP_MODEL_ID
 * - QWEN_NEXT_AWQ_HTTP_CONTEXT
 * - QWEN_NEXT_AWQ_HTTP_MAX_TOKENS
 */
export default function (pi: ExtensionAPI) {
  const BASE_URL = process.env.QWEN_NEXT_AWQ_HTTP_BASE_URL;
  if (!BASE_URL) {
    return;
  }
  const MODEL_ID = process.env.QWEN_NEXT_AWQ_HTTP_MODEL_ID ?? "bullpoint/Qwen3-Coder-Next-AWQ-4bit";
  const CONTEXT_WINDOW = Number(process.env.QWEN_NEXT_AWQ_HTTP_CONTEXT) || 65536;
  const MAX_TOKENS = Number(process.env.QWEN_NEXT_AWQ_HTTP_MAX_TOKENS) || 8192;

  pi.registerProvider("qwen-next-awq-http", {
    name: "Qwen3-Coder-Next AWQ HTTP Endpoint",
    baseUrl: BASE_URL,
    api: "openai-completions",
    apiKey: "unused",
    authHeader: false,
    models: [
      {
        id: MODEL_ID,
        name: "Qwen3-Coder-Next AWQ 4-bit (HTTP)",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: CONTEXT_WINDOW,
        maxTokens: MAX_TOKENS,
        temperature: 0.2,
      },
    ],
  });
}
