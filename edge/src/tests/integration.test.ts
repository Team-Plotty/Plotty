import test from "node:test";
import assert from "node:assert/strict";
import {
  createChatMessagesHandler,
  createDeleteEntityHandler,
  createGetEntitiesHandler,
  createInMemoryDatabase,
  createInMemoryPersistenceRepository,
  createPatchEntityHandler,
  createSimpleCryptoService
} from "../index.js";
import type { AuthVerifier } from "../services/auth.js";
import type { GroqClient } from "../services/groq-client.js";
import type { RateLimiter } from "../services/rate-limit.js";
import type { UserSettingsRepository } from "../services/user-settings.js";
import { createInMemoryGroqUsageRepository } from "../adapters/supabase-groq-usage.js";

const authVerifier: AuthVerifier = {
  async verifyAccessToken(): Promise<{ userId: string }> {
    return { userId: "11111111-1111-1111-1111-111111111111" };
  }
};

const userSettingsRepository: UserSettingsRepository = {
  async findByUserId() {
    return {
      timezone: "Asia/Tokyo",
      aiPersonaConfig: {
        name: "Plotty",
        tone: "friendly",
        identity: "優秀な秘書",
        prohibited_topics: []
      }
    };
  },
  async ensureEncryptionKeyId() {}
};

const groqClient: GroqClient = {
  async extract(input) {
    return {
      extraction: {
        entities: [
          {
            type: "task",
            data: {
              title: "資料の提出",
              content: "明日までに資料を提出する",
              due_date: new Date("2026-05-07T14:59:59.000Z").toISOString()
            }
          }
        ],
        reply_message: "タスクを登録したよ！"
      },
      tokensUsed: 100
    };
  }
};

test("chat -> get -> patch -> delete integration flow", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();

  const chatHandler = createChatMessagesHandler({
    authVerifier,
    userSettingsRepository,
    groqClient,
    groqUsageRepository: createInMemoryGroqUsageRepository(),
    groqDailyTokenLimit: 50000,
    cryptoService,
    persistenceRepository
  });

  const createResult = await chatHandler({
    authorizationHeader: "Bearer test-token",
    body: {
      text: "明日までに資料提出",
      forced_category: null,
      client_message_id: "client-1"
    }
  });

  assert.equal(createResult.status, 200);
  const created = createResult.body as {
    created_entities: Array<{ id: string; type: "task" }>;
  };
  assert.equal(created.created_entities.length, 1);
  const createdTaskId = created.created_entities[0]?.id;
  assert.ok(createdTaskId);

  const getHandler = createGetEntitiesHandler({
    authVerifier,
    cryptoService,
    persistenceRepository
  });
  const getResult = await getHandler({
    authorizationHeader: "Bearer test-token",
    query: { type: "task", limit: "10" }
  });
  assert.equal(getResult.status, 200);
  const getBody = getResult.body as {
    items: Array<{ id: string; title: string; type: string; is_completed: boolean; priority: number }>;
  };
  assert.equal(getBody.items.length, 1);
  assert.equal(getBody.items[0]?.title, "資料の提出");
  assert.equal(getBody.items[0]?.type, "task");
  assert.equal(getBody.items[0]?.is_completed, false);
  assert.equal(getBody.items[0]?.priority, 2);

  const patchHandler = createPatchEntityHandler({
    authVerifier,
    cryptoService,
    persistenceRepository
  });
  const patchResult = await patchHandler({
    authorizationHeader: "Bearer test-token",
    type: "task",
    id: createdTaskId,
    body: {
      title: "資料の最終提出",
      due_date: new Date("2026-05-08T14:59:59.000Z").toISOString()
    }
  });
  assert.equal(patchResult.status, 200);
  const patched = patchResult.body as { entity: { title: string } };
  assert.equal(patched.entity.title, "資料の最終提出");

  const deleteHandler = createDeleteEntityHandler({
    authVerifier,
    persistenceRepository
  });
  const deleteResult = await deleteHandler({
    authorizationHeader: "Bearer test-token",
    type: "task",
    id: createdTaskId
  });
  assert.equal(deleteResult.status, 200);

  const getAfterDelete = await getHandler({
    authorizationHeader: "Bearer test-token",
    query: { type: "task", limit: "10" }
  });
  assert.equal(getAfterDelete.status, 200);
  const getAfterDeleteBody = getAfterDelete.body as { items: Array<unknown> };
  assert.equal(getAfterDeleteBody.items.length, 0);
});

test("reclassify task to memo", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();

  const chatHandler = createChatMessagesHandler({
    authVerifier,
    userSettingsRepository,
    groqClient,
    groqUsageRepository: createInMemoryGroqUsageRepository(),
    groqDailyTokenLimit: 50000,
    cryptoService,
    persistenceRepository
  });

  const createResult = await chatHandler({
    authorizationHeader: "Bearer test-token",
    body: {
      text: "明日までに資料提出",
      forced_category: null,
      client_message_id: "client-reclassify-1"
    }
  });
  assert.equal(createResult.status, 200);
  const created = createResult.body as {
    created_entities: Array<{ id: string; type: "task" }>;
  };
  const taskId = created.created_entities[0]?.id;
  assert.ok(taskId);

  const { createReclassifyHandler } = await import("../app/reclassify-handler.js");
  const reclassifyHandler = createReclassifyHandler({
    authVerifier,
    cryptoService,
    persistenceRepository,
    userSettingsRepository
  });

  const reclassifyResult = await reclassifyHandler({
    authorizationHeader: "Bearer test-token",
    body: {
      source: { type: "task", id: taskId },
      target_type: "memo",
      reason_text: "やっぱりメモにしたい"
    }
  });
  assert.equal(reclassifyResult.status, 200);
  const body = reclassifyResult.body as {
    confirmation_text: string;
    migrated_entity: { type: string; id: string; title: string };
  };
  assert.equal(body.migrated_entity.type, "memo");
  assert.notEqual(body.migrated_entity.id, taskId);
  assert.equal(body.migrated_entity.title, "資料の提出");

  const getHandler = createGetEntitiesHandler({
    authVerifier,
    cryptoService,
    persistenceRepository
  });
  const tasks = await getHandler({
    authorizationHeader: "Bearer test-token",
    query: { type: "task", limit: "10" }
  });
  const memos = await getHandler({
    authorizationHeader: "Bearer test-token",
    query: { type: "memo", limit: "10" }
  });
  assert.equal((tasks.body as { items: unknown[] }).items.length, 0);
  assert.equal((memos.body as { items: unknown[] }).items.length, 1);
});

test("reclassify rejects source older than 30 days", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();

  const chatHandler = createChatMessagesHandler({
    authVerifier,
    userSettingsRepository,
    groqClient,
    groqUsageRepository: createInMemoryGroqUsageRepository(),
    groqDailyTokenLimit: 50000,
    cryptoService,
    persistenceRepository
  });

  const createResult = await chatHandler({
    authorizationHeader: "Bearer test-token",
    body: {
      text: "明日までに資料提出",
      forced_category: null,
      client_message_id: "client-reclassify-expired-1"
    }
  });
  assert.equal(createResult.status, 200);
  const created = createResult.body as {
    created_entities: Array<{ id: string; type: "task" }>;
  };
  const taskId = created.created_entities[0]?.id;
  assert.ok(taskId);

  const userMessage = db.messages.find((message) => message.role === "user");
  assert.ok(userMessage);
  userMessage.createdAt = new Date(Date.now() - 31 * 24 * 60 * 60 * 1000).toISOString();

  const { createReclassifyHandler } = await import("../app/reclassify-handler.js");
  const { reclassifyExpiredMessage } = await import("../services/reclassify-policy.js");
  const reclassifyHandler = createReclassifyHandler({
    authVerifier,
    cryptoService,
    persistenceRepository,
    userSettingsRepository
  });

  const reclassifyResult = await reclassifyHandler({
    authorizationHeader: "Bearer test-token",
    body: {
      source: { type: "task", id: taskId },
      target_type: "memo",
      reason_text: "期限切れテスト"
    }
  });
  assert.equal(reclassifyResult.status, 403);
  const body = reclassifyResult.body as { error: { code: string; message: string } };
  assert.equal(body.error.code, "FORBIDDEN");
  assert.equal(body.error.message, reclassifyExpiredMessage);
});

test("chat messages idempotency returns same response", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();
  let groqCalls = 0;
  const countingGroqClient: GroqClient = {
    async extract(input) {
      groqCalls += 1;
      return {
        extraction: {
          entities: [
            {
              type: "task",
              data: {
                title: "資料の提出",
                content: "明日までに資料を提出する",
                due_date: "2026-06-17T23:59:59+09:00"
              }
            }
          ],
          reply_message: "タスクを登録したよ！"
        },
        tokensUsed: 100
      };
    }
  };

  const chatHandler = createChatMessagesHandler({
    authVerifier,
    userSettingsRepository,
    groqClient: countingGroqClient,
    groqUsageRepository: createInMemoryGroqUsageRepository(),
    groqDailyTokenLimit: 50000,
    cryptoService,
    persistenceRepository
  });

  const body = {
    text: "明日までに資料提出",
    forced_category: null,
    client_message_id: "client-idempotent-1"
  };

  const first = await chatHandler({
    authorizationHeader: "Bearer test-token",
    body
  });
  const second = await chatHandler({
    authorizationHeader: "Bearer test-token",
    body
  });

  assert.equal(first.status, 200);
  assert.equal(second.status, 200);
  assert.deepEqual(second.body, first.body);
  assert.equal(groqCalls, 1);
});

test("chat stores schedule end time and task due time flags", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();
  const timedGroqClient: GroqClient = {
    async extract() {
      return {
        extraction: {
          entities: [
            {
              type: "schedule",
              data: {
                title: "会議",
                start_at: "2026-10-11T10:00:00+09:00",
                end_at: "2026-10-11T12:00:00+09:00",
                is_all_day: false
              }
            },
            {
              type: "task",
              data: {
                title: "資料提出",
                due_date: "2026-10-16T18:00:00+09:00",
                due_has_time: true
              }
            },
            {
              type: "task",
              data: { title: "掃除" }
            }
          ],
          reply_message: "登録したよ！"
        },
        tokensUsed: 100
      };
    }
  };

  const chatHandler = createChatMessagesHandler({
    authVerifier,
    userSettingsRepository,
    groqClient: timedGroqClient,
    groqUsageRepository: createInMemoryGroqUsageRepository(),
    groqDailyTokenLimit: 50000,
    cryptoService,
    persistenceRepository
  });

  const result = await chatHandler({
    authorizationHeader: "Bearer test-token",
    body: {
      text: "明日10時から12時まで会議、金曜18時までに資料提出、掃除",
      forced_category: null,
      client_message_id: "client-timed-1"
    }
  });
  assert.equal(result.status, 200);
  const body = result.body as {
    created_entities: Array<Record<string, unknown>>;
  };
  const [schedule, timedTask, untimedTask] = body.created_entities;
  assert.equal(schedule?.end_at, "2026-10-11T03:00:00.000Z");
  assert.equal(schedule?.is_all_day, false);
  assert.equal(timedTask?.due_date, "2026-10-16T09:00:00.000Z");
  assert.equal(timedTask?.due_has_time, true);
  assert.equal(untimedTask?.due_has_time, false);

  const patchHandler = createPatchEntityHandler({
    authVerifier,
    cryptoService,
    persistenceRepository
  });
  const patchResult = await patchHandler({
    authorizationHeader: "Bearer test-token",
    type: "task",
    id: String(untimedTask?.id),
    body: { due_date: "2026-10-12T09:30:00+09:00", due_has_time: true }
  });
  assert.equal(patchResult.status, 200);
  const patched = patchResult.body as { entity: { due_has_time: boolean } };
  assert.equal(patched.entity.due_has_time, true);
});

test("chat returns a question with no entities when the request is ambiguous", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();
  const askingGroqClient: GroqClient = {
    async extract() {
      return {
        extraction: { entities: [], reply_message: "いつの予定ですか？" },
        tokensUsed: 50
      };
    }
  };

  const chatHandler = createChatMessagesHandler({
    authVerifier,
    userSettingsRepository,
    groqClient: askingGroqClient,
    groqUsageRepository: createInMemoryGroqUsageRepository(),
    groqDailyTokenLimit: 50000,
    cryptoService,
    persistenceRepository
  });

  const result = await chatHandler({
    authorizationHeader: "Bearer test-token",
    body: { text: "バイトがある", forced_category: null, client_message_id: "client-ask-1" }
  });

  assert.equal(result.status, 200);
  const body = result.body as { confirmation_text: string; created_entities: unknown[] };
  assert.equal(body.confirmation_text, "いつの予定ですか？");
  assert.equal(body.created_entities.length, 0);
  assert.equal(db.schedules.length + db.tasks.length + db.memos.length, 0);
  assert.equal(db.messages.length, 2);
});

test("chat passes recent conversation to the extractor as history", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();
  const receivedHistories: Array<Array<{ role: string; content: string }>> = [];
  const recordingGroqClient: GroqClient = {
    async extract(input) {
      receivedHistories.push(input.history ?? []);
      return {
        extraction: { entities: [], reply_message: "何時からですか？" },
        tokensUsed: 50
      };
    }
  };

  const chatHandler = createChatMessagesHandler({
    authVerifier,
    userSettingsRepository,
    groqClient: recordingGroqClient,
    groqUsageRepository: createInMemoryGroqUsageRepository(),
    groqDailyTokenLimit: 50000,
    cryptoService,
    persistenceRepository
  });

  await chatHandler({
    authorizationHeader: "Bearer test-token",
    body: { text: "明日バイト", forced_category: null, client_message_id: "client-history-1" }
  });
  await chatHandler({
    authorizationHeader: "Bearer test-token",
    body: { text: "15時から", forced_category: null, client_message_id: "client-history-2" }
  });

  assert.deepEqual(receivedHistories[0], []);
  assert.deepEqual(receivedHistories[1], [
    { role: "user", content: "明日バイト" },
    { role: "assistant", content: "何時からですか？" }
  ]);
});

test("chat messages returns 401 without bearer token", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();
  const chatHandler = createChatMessagesHandler({
    authVerifier,
    userSettingsRepository,
    groqClient,
    groqUsageRepository: createInMemoryGroqUsageRepository(),
    groqDailyTokenLimit: 50000,
    cryptoService,
    persistenceRepository
  });

  const result = await chatHandler({
    authorizationHeader: null,
    body: {
      text: "テスト",
      forced_category: null,
      client_message_id: "client-2"
    }
  });

  assert.equal(result.status, 401);
});
