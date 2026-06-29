import type { SupabaseClient } from "@supabase/supabase-js";
import type {
  EntityReadFilter,
  EntityReadModel,
  EntityUpdateInput,
  MemoWriteInput,
  MessageListFilter,
  MessageReadModel,
  MessageWriteInput,
  PersistenceRepository,
  RelatedEntityRef,
  ScheduleWriteInput,
  TaskWriteInput
} from "../services/persistence.js";

const SCHEDULE_SELECT =
  "id,user_id,title_encrypted,iv,origin_text_encrypted,start_at,end_at,is_all_day,location,created_at,source_message_id,updated_at";
const TASK_SELECT =
  "id,user_id,title_encrypted,iv,due_date,is_completed,priority,created_at,source_message_id,updated_at";
const MEMO_SELECT =
  "id,user_id,title_encrypted,iv,content_encrypted,is_pinned,created_at,source_message_id,updated_at";

const rowToScheduleReadModel = (row: Record<string, unknown>): EntityReadModel => ({
  type: "schedule",
  id: String(row.id),
  userId: String(row.user_id),
  titleEncrypted: String(row.title_encrypted),
  iv: String(row.iv),
  originTextEncrypted: row.origin_text_encrypted ? String(row.origin_text_encrypted) : undefined,
  startAt: row.start_at ? String(row.start_at) : undefined,
  endAt: row.end_at ? String(row.end_at) : null,
  isAllDay: Boolean(row.is_all_day),
  location: row.location ? String(row.location) : null,
  createdAt: row.created_at ? String(row.created_at) : undefined,
  sourceMessageId: row.source_message_id ? String(row.source_message_id) : null,
  updatedAt: row.updated_at ? String(row.updated_at) : undefined
});

const rowToTaskReadModel = (row: Record<string, unknown>): EntityReadModel => ({
  type: "task",
  id: String(row.id),
  userId: String(row.user_id),
  titleEncrypted: String(row.title_encrypted),
  iv: String(row.iv),
  dueDate: row.due_date ? String(row.due_date) : undefined,
  isCompleted: Boolean(row.is_completed),
  priority: row.priority ? (Number(row.priority) as 1 | 2 | 3) : 2,
  createdAt: row.created_at ? String(row.created_at) : undefined,
  sourceMessageId: row.source_message_id ? String(row.source_message_id) : null,
  updatedAt: row.updated_at ? String(row.updated_at) : undefined
});

const rowToMemoReadModel = (row: Record<string, unknown>): EntityReadModel => ({
  type: "memo",
  id: String(row.id),
  userId: String(row.user_id),
  titleEncrypted: String(row.title_encrypted),
  iv: String(row.iv),
  contentEncrypted: row.content_encrypted ? String(row.content_encrypted) : undefined,
  isPinned: Boolean(row.is_pinned),
  createdAt: row.created_at ? String(row.created_at) : undefined,
  sourceMessageId: row.source_message_id ? String(row.source_message_id) : null,
  updatedAt: row.updated_at ? String(row.updated_at) : undefined
});

const sortByUpdatedAtDesc = (items: EntityReadModel[]): EntityReadModel[] =>
  [...items].sort((a, b) => {
    const aTime = a.updatedAt ? Date.parse(a.updatedAt) : 0;
    const bTime = b.updatedAt ? Date.parse(b.updatedAt) : 0;
    return bTime - aTime;
  });

export const createSupabasePersistenceRepository = (
  supabase: SupabaseClient
): PersistenceRepository => ({
  async insertMessage(input: MessageWriteInput): Promise<void> {
    const { error } = await supabase.from("messages").insert({
      id: input.id,
      user_id: input.userId,
      role: input.role,
      client_message_id: input.clientMessageId ?? null,
      content_encrypted: input.contentEncrypted,
      iv: input.iv,
      related_entities: input.relatedEntities,
      analysis_results_encrypted: input.analysisResultsEncrypted
        ? { iv: input.analysisResultsEncrypted.iv, data: input.analysisResultsEncrypted.data }
        : null,
      expires_at: input.expiresAt
    });
    if (error) throw error;
  },
  async updateMessageRelatedEntities(input: {
    id: string;
    userId: string;
    relatedEntities: RelatedEntityRef[];
  }): Promise<void> {
    const { error } = await supabase
      .from("messages")
      .update({ related_entities: input.relatedEntities })
      .eq("id", input.id)
      .eq("user_id", input.userId);
    if (error) throw error;
  },
  async insertSchedule(input: ScheduleWriteInput): Promise<void> {
    const { error } = await supabase.from("schedules").insert({
      id: input.id,
      user_id: input.userId,
      source_message_id: input.sourceMessageId,
      origin_text_encrypted: input.originTextEncrypted,
      title_encrypted: input.titleEncrypted,
      title_hash: input.titleHash,
      iv: input.iv,
      start_at: input.startAt,
      end_at: input.endAt,
      is_all_day: input.isAllDay,
      location: input.location
    });
    if (error) throw error;
  },
  async insertTask(input: TaskWriteInput): Promise<void> {
    const { error } = await supabase.from("tasks").insert({
      id: input.id,
      user_id: input.userId,
      source_message_id: input.sourceMessageId,
      origin_text_encrypted: input.originTextEncrypted,
      title_encrypted: input.titleEncrypted,
      title_hash: input.titleHash,
      iv: input.iv,
      due_date: input.dueDate,
      priority: input.priority,
      is_completed: input.isCompleted
    });
    if (error) throw error;
  },
  async insertMemo(input: MemoWriteInput): Promise<void> {
    const { error } = await supabase.from("memos").insert({
      id: input.id,
      user_id: input.userId,
      source_message_id: input.sourceMessageId,
      origin_text_encrypted: input.originTextEncrypted,
      title_encrypted: input.titleEncrypted,
      title_hash: input.titleHash,
      iv: input.iv,
      content_encrypted: input.contentEncrypted,
      is_pinned: input.isPinned
    });
    if (error) throw error;
  },
  async listEntities(filter: EntityReadFilter): Promise<EntityReadModel[]> {
    const limit = filter.limit;
    if (filter.type === "schedule") {
      const { data, error } = await supabase
        .from("schedules")
        .select(SCHEDULE_SELECT)
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .order("updated_at", { ascending: false })
        .limit(limit);
      if (error) throw error;
      return (data ?? []).map((row) => rowToScheduleReadModel(row));
    }
    if (filter.type === "task") {
      const { data, error } = await supabase
        .from("tasks")
        .select(TASK_SELECT)
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .order("updated_at", { ascending: false })
        .limit(limit);
      if (error) throw error;
      return (data ?? []).map((row) => rowToTaskReadModel(row));
    }
    if (filter.type === "memo") {
      const { data, error } = await supabase
        .from("memos")
        .select(MEMO_SELECT)
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .order("updated_at", { ascending: false })
        .limit(limit);
      if (error) throw error;
      return (data ?? []).map((row) => rowToMemoReadModel(row));
    }

    const [schedules, tasks, memos] = await Promise.all([
      supabase
        .from("schedules")
        .select(SCHEDULE_SELECT)
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .order("updated_at", { ascending: false })
        .limit(limit),
      supabase
        .from("tasks")
        .select(TASK_SELECT)
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .order("updated_at", { ascending: false })
        .limit(limit),
      supabase
        .from("memos")
        .select(MEMO_SELECT)
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .order("updated_at", { ascending: false })
        .limit(limit)
    ]);

    if (schedules.error) throw schedules.error;
    if (tasks.error) throw tasks.error;
    if (memos.error) throw memos.error;

    return sortByUpdatedAtDesc([
      ...(schedules.data ?? []).map((row) => rowToScheduleReadModel(row)),
      ...(tasks.data ?? []).map((row) => rowToTaskReadModel(row)),
      ...(memos.data ?? []).map((row) => rowToMemoReadModel(row))
    ]).slice(0, limit);
  },
  async getEntityById(input: {
    userId: string;
    type: "schedule" | "task" | "memo";
    id: string;
  }): Promise<EntityReadModel | null> {
    const table =
      input.type === "schedule" ? "schedules" : input.type === "task" ? "tasks" : "memos";
    const selectColumns =
      input.type === "schedule" ? SCHEDULE_SELECT : input.type === "task" ? TASK_SELECT : MEMO_SELECT;
    const { data, error } = await supabase
      .from(table)
      .select(selectColumns)
      .eq("id", input.id)
      .eq("user_id", input.userId)
      .eq("is_deleted", false)
      .maybeSingle();
    if (error) throw error;
    if (!data) return null;
    const row = data as unknown as Record<string, unknown>;
    if (input.type === "schedule") return rowToScheduleReadModel(row);
    if (input.type === "task") return rowToTaskReadModel(row);
    return rowToMemoReadModel(row);
  },
  async findUserMessageByClientMessageId(userId: string, clientMessageId: string) {
    const { data, error } = await supabase
      .from("messages")
      .select("id,related_entities,analysis_results_encrypted")
      .eq("user_id", userId)
      .eq("client_message_id", clientMessageId)
      .eq("role", "user")
      .maybeSingle();
    if (error) throw error;
    if (!data?.analysis_results_encrypted) return null;
    const analysis = data.analysis_results_encrypted as { iv: string; data: string };
    return {
      id: String(data.id),
      relatedEntities: (data.related_entities ?? []) as Array<{
        type: "schedule" | "task" | "memo";
        id: string;
      }>,
      analysisResultsEncrypted: { iv: analysis.iv, data: analysis.data }
    };
  },
  async updateEntity(input: EntityUpdateInput): Promise<EntityReadModel | null> {
    const table = input.type === "schedule" ? "schedules" : input.type === "task" ? "tasks" : "memos";
    const updatePayload: Record<string, unknown> = {};
    if (input.titleEncrypted !== undefined) updatePayload.title_encrypted = input.titleEncrypted;
    if (input.titleHash !== undefined) updatePayload.title_hash = input.titleHash;
    if (input.iv !== undefined) updatePayload.iv = input.iv;
    if (input.originTextEncrypted !== undefined) {
      updatePayload.origin_text_encrypted = input.originTextEncrypted;
    }
    if (input.startAt !== undefined) updatePayload.start_at = input.startAt;
    if (input.endAt !== undefined) updatePayload.end_at = input.endAt;
    if (input.isAllDay !== undefined) updatePayload.is_all_day = input.isAllDay;
    if (input.location !== undefined) updatePayload.location = input.location;
    if (input.dueDate !== undefined) updatePayload.due_date = input.dueDate;
    if (input.isCompleted !== undefined) updatePayload.is_completed = input.isCompleted;
    if (input.priority !== undefined) updatePayload.priority = input.priority;
    if (input.contentEncrypted !== undefined) updatePayload.content_encrypted = input.contentEncrypted;
    if (input.isPinned !== undefined) updatePayload.is_pinned = input.isPinned;

    const selectColumns =
      input.type === "schedule" ? SCHEDULE_SELECT : input.type === "task" ? TASK_SELECT : MEMO_SELECT;

    const { data, error } = await supabase
      .from(table)
      .update(updatePayload)
      .eq("id", input.id)
      .eq("user_id", input.userId)
      .eq("is_deleted", false)
      .select(selectColumns)
      .maybeSingle();

    if (error) throw error;
    if (!data) return null;

    const row = data as unknown as Record<string, unknown>;
    if (input.type === "schedule") return rowToScheduleReadModel(row);
    if (input.type === "task") return rowToTaskReadModel(row);
    return rowToMemoReadModel(row);
  },
  async softDeleteEntity(input: {
    id: string;
    userId: string;
    type: "schedule" | "task" | "memo";
  }): Promise<boolean> {
    const table = input.type === "schedule" ? "schedules" : input.type === "task" ? "tasks" : "memos";
    const { data, error } = await supabase
      .from(table)
      .update({ is_deleted: true })
      .eq("id", input.id)
      .eq("user_id", input.userId)
      .eq("is_deleted", false)
      .select("id")
      .maybeSingle();
    if (error) throw error;
    return Boolean(data?.id);
  },
  async replaceRelatedEntityRef(input: {
    userId: string;
    oldEntityId: string;
    newEntityId: string;
    newType: "schedule" | "task" | "memo";
  }): Promise<void> {
    const { data, error } = await supabase
      .from("messages")
      .select("id,related_entities")
      .eq("user_id", input.userId);
    if (error) throw error;

    for (const message of data ?? []) {
      const related = message.related_entities as Array<{ type: string; id: string }>;
      if (!Array.isArray(related)) continue;
      const index = related.findIndex((item) => item.id === input.oldEntityId);
      if (index < 0) continue;
      const updated = [...related];
      updated[index] = { type: input.newType, id: input.newEntityId };
      const { error: updateError } = await supabase
        .from("messages")
        .update({ related_entities: updated })
        .eq("id", message.id)
        .eq("user_id", input.userId);
      if (updateError) throw updateError;
    }
  },
  async listMessages(filter: MessageListFilter): Promise<MessageReadModel[]> {
    const { data, error } = await supabase
      .from("messages")
      .select("id,user_id,role,content_encrypted,iv,related_entities,created_at")
      .eq("user_id", filter.userId)
      .order("created_at", { ascending: true })
      .limit(filter.limit);
    if (error) throw error;

    return (data ?? []).map((row) => ({
      id: String(row.id),
      userId: String(row.user_id),
      role: row.role as "user" | "assistant",
      contentEncrypted: String(row.content_encrypted),
      iv: String(row.iv),
      relatedEntities: (row.related_entities ?? []) as RelatedEntityRef[],
      createdAt: String(row.created_at)
    }));
  },
  async findMessageById(userId: string, messageId: string) {
    const { data, error } = await supabase
      .from("messages")
      .select("created_at")
      .eq("user_id", userId)
      .eq("id", messageId)
      .maybeSingle();
    if (error) throw error;
    if (!data?.created_at) return null;
    return { createdAt: String(data.created_at) };
  }
});
