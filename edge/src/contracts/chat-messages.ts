import { z } from "zod";

export const entityTypeSchema = z.enum(["schedule", "task", "memo"]);
export type EntityType = z.infer<typeof entityTypeSchema>;

export const postChatMessagesRequestSchema = z.object({
  text: z.string().min(1).max(4000),
  forced_category: entityTypeSchema.nullable(),
  client_message_id: z.string().min(1).max(128)
});

export type PostChatMessagesRequest = z.infer<
  typeof postChatMessagesRequestSchema
>;

export const llmEntityDataSchema = z.object({
  title: z.string().min(1).max(20),
  start_at: z.string().datetime().optional(),
  due_date: z.string().datetime().optional(),
  content: z.string().min(1).max(4000)
});

export const llmEntitySchema = z.object({
  type: entityTypeSchema,
  data: llmEntityDataSchema
});

export const llmExtractionResultSchema = z.object({
  entities: z.array(llmEntitySchema),
  reply_message: z.string().min(1).max(1000)
});

export type LlmExtractionResult = z.infer<typeof llmExtractionResultSchema>;

export const createdEntitySchema = z.object({
  type: entityTypeSchema,
  id: z.string().uuid(),
  title: z.string().min(1),
  start_at: z.string().datetime().optional(),
  due_date: z.string().datetime().optional()
});

export const postChatMessagesResponseSchema = z.object({
  message_id: z.string().uuid(),
  confirmation_text: z.string().min(1),
  created_entities: z.array(createdEntitySchema)
});

export type PostChatMessagesResponse = z.infer<
  typeof postChatMessagesResponseSchema
>;

export const getEntitiesQuerySchema = z.object({
  type: entityTypeSchema.optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50)
});

export type GetEntitiesQuery = z.infer<typeof getEntitiesQuerySchema>;

export const entityListItemSchema = z.object({
  type: entityTypeSchema,
  id: z.string().uuid(),
  title: z.string().min(1),
  start_at: z.string().datetime().optional(),
  due_date: z.string().datetime().optional()
});

export const getEntitiesResponseSchema = z.object({
  items: z.array(entityListItemSchema),
  next_cursor: z.string().nullable()
});

export type GetEntitiesResponse = z.infer<typeof getEntitiesResponseSchema>;
