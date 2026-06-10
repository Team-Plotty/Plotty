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
} from "../index.ts";
import type { AuthVerifier } from "../services/auth.ts";
import type { GroqClient } from "../services/groq-client.ts";
import type { RateLimiter } from "../services/rate-limit.ts";
import type { UserSettingsRepository } from "../services/user-settings.ts";
import { createInMemoryGroqUsageRepository } from "../adapters/supabase-groq-usage.ts";

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

  const { createReclassifyHandler } = await import("../app/reclassify-handler.ts");
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

test("chat messages idempotency returns same response", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();
  let groqCalls = 0;
  const countingGroqClient: GroqClient = {
    async extract(input) {
      groqCalls += 1;
      return groqClient.extract(input);
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
