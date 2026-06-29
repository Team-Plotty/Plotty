import { z } from "zod";

export const entityTypeSchema = z.enum(["schedule", "task", "memo"]);
export type EntityType = z.infer<typeof entityTypeSchema>;

/** API の日時フィールド（Groq 抽出の offset 付き ISO-8601 を許容） */
const isoDateTimeSchema = z.string().datetime({ offset: true });

export const postChatMessagesRequestSchema = z.object({
  text: z.string().min(1).max(4000),
  forced_category: entityTypeSchema.nullable(),
  client_message_id: z.string().min(1).max(128)
});

export type PostChatMessagesRequest = z.infer<typeof postChatMessagesRequestSchema>;

export const llmEntityDataSchema = z.object({
  title: z.string().min(1).max(20),
  start_at: z.string().datetime({ offset: true }).optional(),
  due_date: z.string().datetime({ offset: true }).optional(),
  content: z
    .union([z.string().min(1).max(4000), z.literal("")])
    .optional()
    .transform((value) => (value === "" ? undefined : value))
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

export const scheduleEntityDtoSchema = z.object({
  type: z.literal("schedule"),
  id: z.string().uuid(),
  title: z.string().min(1).max(100),
  start_at: isoDateTimeSchema,
  end_at: isoDateTimeSchema.nullable(),
  is_all_day: z.boolean(),
  location: z.string(),
  notes: z.string(),
  updated_at: isoDateTimeSchema
});

export const taskEntityDtoSchema = z.object({
  type: z.literal("task"),
  id: z.string().uuid(),
  title: z.string().min(1).max(100),
  is_completed: z.boolean(),
  due_date: isoDateTimeSchema,
  priority: z.number().int().min(1).max(3),
  created_at: isoDateTimeSchema,
  updated_at: isoDateTimeSchema
});

export const memoEntityDtoSchema = z.object({
  type: z.literal("memo"),
  id: z.string().uuid(),
  title: z.string().min(1).max(100),
  content: z.string().min(1).max(4000),
  is_pinned: z.boolean(),
  updated_at: isoDateTimeSchema
});

export const entityDtoSchema = z.discriminatedUnion("type", [
  scheduleEntityDtoSchema,
  taskEntityDtoSchema,
  memoEntityDtoSchema
]);

export type EntityDto = z.infer<typeof entityDtoSchema>;
export type ScheduleEntityDto = z.infer<typeof scheduleEntityDtoSchema>;
export type TaskEntityDto = z.infer<typeof taskEntityDtoSchema>;
export type MemoEntityDto = z.infer<typeof memoEntityDtoSchema>;

export const createdScheduleEntitySchema = scheduleEntityDtoSchema.omit({ updated_at: true });
export const createdTaskEntitySchema = taskEntityDtoSchema.omit({
  created_at: true,
  updated_at: true
});
export const createdMemoEntitySchema = memoEntityDtoSchema.omit({ updated_at: true });

export const createdEntitySchema = z.discriminatedUnion("type", [
  createdScheduleEntitySchema,
  createdTaskEntitySchema,
  createdMemoEntitySchema
]);

export type CreatedEntityDto = z.infer<typeof createdEntitySchema>;

export const postChatMessagesResponseSchema = z.object({
  message_id: z.string().uuid(),
  assistant_message_id: z.string().uuid(),
  confirmation_text: z.string().min(1),
  created_entities: z.array(createdEntitySchema)
});

export type PostChatMessagesResponse = z.infer<typeof postChatMessagesResponseSchema>;

export const getChatMessagesQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(200).default(100)
});

export type GetChatMessagesQuery = z.infer<typeof getChatMessagesQuerySchema>;

export const chatHistoryMessageSchema = z.object({
  id: z.string().uuid(),
  role: z.enum(["user", "assistant"]),
  text: z.string(),
  created_at: isoDateTimeSchema,
  created_entities: z.array(createdEntitySchema).optional()
});

export type ChatHistoryMessage = z.infer<typeof chatHistoryMessageSchema>;

export const getChatMessagesResponseSchema = z.object({
  items: z.array(chatHistoryMessageSchema)
});

export type GetChatMessagesResponse = z.infer<typeof getChatMessagesResponseSchema>;

export const getEntitiesQuerySchema = z.object({
  type: entityTypeSchema.optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50)
});

export type GetEntitiesQuery = z.infer<typeof getEntitiesQuerySchema>;

export const getEntitiesResponseSchema = z.object({
  items: z.array(entityDtoSchema),
  next_cursor: z.string().nullable()
});

export type GetEntitiesResponse = z.infer<typeof getEntitiesResponseSchema>;

export const patchEntityRequestSchema = z.object({
  title: z.string().min(1).max(100).optional(),
  start_at: isoDateTimeSchema.optional(),
  end_at: isoDateTimeSchema.nullable().optional(),
  is_all_day: z.boolean().optional(),
  location: z.string().optional(),
  notes: z.string().optional(),
  is_completed: z.boolean().optional(),
  due_date: isoDateTimeSchema.optional(),
  priority: z.number().int().min(1).max(3).optional(),
  content: z.string().min(1).max(4000).optional(),
  is_pinned: z.boolean().optional()
});

export type PatchEntityRequest = z.infer<typeof patchEntityRequestSchema>;

export const patchEntityResponseSchema = z.object({
  entity: entityDtoSchema
});

export type PatchEntityResponse = z.infer<typeof patchEntityResponseSchema>;

export const deleteEntityResponseSchema = z.object({
  deleted: z.literal(true),
  type: entityTypeSchema,
  id: z.string().uuid()
});

export type DeleteEntityResponse = z.infer<typeof deleteEntityResponseSchema>;

/** @deprecated entityListItemSchema は entityDtoSchema に統合 */
export const entityListItemSchema = entityDtoSchema;
