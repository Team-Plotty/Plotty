import type { SupabaseClient } from "@supabase/supabase-js";
import type {
  EntityReadFilter,
  EntityReadModel,
  EntityUpdateInput,
  MemoWriteInput,
  MessageWriteInput,
  PersistenceRepository,
  ScheduleWriteInput,
  TaskWriteInput
} from "../services/persistence.ts";

const rowToEntityReadModel = (
  type: "schedule" | "task" | "memo",
  row: Record<string, unknown>
): EntityReadModel => ({
  type,
  id: String(row.id),
  userId: String(row.user_id),
  titleEncrypted: String(row.title_encrypted),
  iv: String(row.iv),
  startAt: row.start_at ? String(row.start_at) : undefined,
  dueDate: row.due_date ? String(row.due_date) : undefined,
  contentEncrypted: row.content_encrypted ? String(row.content_encrypted) : undefined
});

export const createSupabasePersistenceRepository = (
  supabase: SupabaseClient
): PersistenceRepository => ({
  async insertMessage(input: MessageWriteInput): Promise<void> {
    const { error } = await supabase.from("messages").insert({
      id: input.id,
      user_id: input.userId,
      role: input.role,
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
      is_completed: false
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
      content_encrypted: input.contentEncrypted
    });
    if (error) throw error;
  },
  async listEntities(filter: EntityReadFilter): Promise<EntityReadModel[]> {
    const limit = filter.limit;
    if (filter.type === "schedule") {
      const { data, error } = await supabase
        .from("schedules")
        .select("id,user_id,title_encrypted,iv,start_at")
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .limit(limit);
      if (error) throw error;
      return (data ?? []).map((row) => rowToEntityReadModel("schedule", row));
    }
    if (filter.type === "task") {
      const { data, error } = await supabase
        .from("tasks")
        .select("id,user_id,title_encrypted,iv,due_date")
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .limit(limit);
      if (error) throw error;
      return (data ?? []).map((row) => rowToEntityReadModel("task", row));
    }
    if (filter.type === "memo") {
      const { data, error } = await supabase
        .from("memos")
        .select("id,user_id,title_encrypted,iv,content_encrypted")
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .limit(limit);
      if (error) throw error;
      return (data ?? []).map((row) => rowToEntityReadModel("memo", row));
    }

    const [schedules, tasks, memos] = await Promise.all([
      supabase
        .from("schedules")
        .select("id,user_id,title_encrypted,iv,start_at")
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .limit(limit),
      supabase
        .from("tasks")
        .select("id,user_id,title_encrypted,iv,due_date")
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .limit(limit),
      supabase
        .from("memos")
        .select("id,user_id,title_encrypted,iv,content_encrypted")
        .eq("user_id", filter.userId)
        .eq("is_deleted", false)
        .limit(limit)
    ]);

    if (schedules.error) throw schedules.error;
    if (tasks.error) throw tasks.error;
    if (memos.error) throw memos.error;

    return [
      ...(schedules.data ?? []).map((row) => rowToEntityReadModel("schedule", row)),
      ...(tasks.data ?? []).map((row) => rowToEntityReadModel("task", row)),
      ...(memos.data ?? []).map((row) => rowToEntityReadModel("memo", row))
    ].slice(0, limit);
  },
  async updateEntity(input: EntityUpdateInput): Promise<EntityReadModel | null> {
    const table = input.type === "schedule" ? "schedules" : input.type === "task" ? "tasks" : "memos";
    const updatePayload: Record<string, unknown> = {};
    if (input.titleEncrypted) updatePayload.title_encrypted = input.titleEncrypted;
    if (input.iv) updatePayload.iv = input.iv;
    if (input.startAt) updatePayload.start_at = input.startAt;
    if (input.dueDate) updatePayload.due_date = input.dueDate;
    if (input.contentEncrypted) updatePayload.content_encrypted = input.contentEncrypted;

    const selectColumns =
      input.type === "schedule"
        ? "id,user_id,title_encrypted,iv,start_at"
        : input.type === "task"
          ? "id,user_id,title_encrypted,iv,due_date"
          : "id,user_id,title_encrypted,iv,content_encrypted";

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
    return rowToEntityReadModel(input.type, data);
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
  }
});
