import { z } from "zod";
import { entityDtoSchema, entityTypeSchema } from "./chat-messages.js";

export const postReclassifyRequestSchema = z
  .object({
    source: z.object({
      type: entityTypeSchema,
      id: z.string().uuid()
    }),
    target_type: entityTypeSchema,
    reason_text: z.string().max(500).optional()
  })
  .refine((value) => value.source.type !== value.target_type, {
    message: "source.type must differ from target_type"
  });

export type PostReclassifyRequest = z.infer<typeof postReclassifyRequestSchema>;

export const postReclassifyResponseSchema = z.object({
  confirmation_text: z.string().min(1),
  migrated_entity: entityDtoSchema
});

export type PostReclassifyResponse = z.infer<typeof postReclassifyResponseSchema>;
