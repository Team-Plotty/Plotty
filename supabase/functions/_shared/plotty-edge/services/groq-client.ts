import { llmExtractionResultSchema, type LlmExtractionResult } from "../contracts/chat-messages.ts";
import { withRetry } from "./retry.ts";

export interface GroqClientConfig {
  apiKey: string;
  model: string;
  timeoutMs: number;
  retries: number;
}

export interface GroqPromptInput {
  systemPrompt: string;
  developerPrompt: string;
  userPrompt: string;
}

export interface GroqClient {
  extract(input: GroqPromptInput): Promise<LlmExtractionResult>;
}

interface GroqChatCompletionResponse {
  choices?: Array<{
    message?: {
      content?: string;
    };
  }>;
}

export const createGroqClient = (config: GroqClientConfig): GroqClient => ({
  async extract(input: GroqPromptInput): Promise<LlmExtractionResult> {
    return withRetry(
      async () => {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), config.timeoutMs);

        try {
          const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${config.apiKey}`
            },
            body: JSON.stringify({
              model: config.model,
              temperature: 0,
              response_format: { type: "json_object" },
              messages: [
                { role: "system", content: input.systemPrompt },
                { role: "system", content: input.developerPrompt },
                { role: "user", content: input.userPrompt }
              ]
            }),
            signal: controller.signal
          });

          if (!response.ok) {
            throw new Error(`Groq API error: ${response.status}`);
          }

          const json = (await response.json()) as GroqChatCompletionResponse;
          const content = json.choices?.[0]?.message?.content;
          if (!content) {
            throw new Error("Groq response content is empty");
          }

          const parsed = llmExtractionResultSchema.safeParse(JSON.parse(content));
          if (!parsed.success) {
            throw new Error("Groq response schema validation failed");
          }

          return parsed.data;
        } finally {
          clearTimeout(timeoutId);
        }
      },
      { retries: config.retries }
    );
  }
});
