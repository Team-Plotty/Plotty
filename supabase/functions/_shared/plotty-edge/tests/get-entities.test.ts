import test from "node:test";
import assert from "node:assert/strict";
import {
  createGetEntitiesHandler,
  createInMemoryDatabase,
  createInMemoryPersistenceRepository,
  createSimpleCryptoService
} from "../index.ts";
import type { AuthVerifier } from "../services/auth.ts";

const authVerifier: AuthVerifier = {
  async verifyAccessToken(): Promise<{ userId: string }> {
    return { userId: "11111111-1111-1111-1111-111111111111" };
  }
};

test("GET /entities returns merged types sorted by updated_at when type omitted", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();
  const titleEnc = await cryptoService.encryptText("タイトル");

  await persistenceRepository.insertSchedule({
    id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    userId: "11111111-1111-1111-1111-111111111111",
    sourceMessageId: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    originTextEncrypted: "enc",
    titleEncrypted: titleEnc.data,
    titleHash: "hash",
    iv: titleEnc.iv,
    startAt: new Date().toISOString(),
    endAt: null,
    isAllDay: false,
    location: null
  });
  await persistenceRepository.insertTask({
    id: "cccccccc-cccc-cccc-cccc-cccccccccccc",
    userId: "11111111-1111-1111-1111-111111111111",
    sourceMessageId: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    originTextEncrypted: "enc",
    titleEncrypted: titleEnc.data,
    titleHash: "hash",
    iv: titleEnc.iv,
    dueDate: new Date().toISOString(),
    priority: 2,
    isCompleted: false
  });

  const handler = createGetEntitiesHandler({
    authVerifier,
    cryptoService,
    persistenceRepository
  });

  const result = await handler({
    authorizationHeader: "Bearer test-token",
    query: { limit: "10" }
  });

  assert.equal(result.status, 200);
  const body = result.body as { items: Array<{ type: string }>; next_cursor: null };
  assert.equal(body.next_cursor, null);
  assert.equal(body.items.length, 2);
  assert.ok(body.items.some((item) => item.type === "schedule"));
  assert.ok(body.items.some((item) => item.type === "task"));
});

test("GET /entities filters by type query", async () => {
  const db = createInMemoryDatabase();
  const persistenceRepository = createInMemoryPersistenceRepository(db);
  const cryptoService = createSimpleCryptoService();
  const titleEnc = await cryptoService.encryptText("メモ");

  await persistenceRepository.insertMemo({
    id: "dddddddd-dddd-dddd-dddd-dddddddddddd",
    userId: "11111111-1111-1111-1111-111111111111",
    sourceMessageId: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    originTextEncrypted: "enc",
    titleEncrypted: titleEnc.data,
    titleHash: "hash",
    iv: titleEnc.iv,
    contentEncrypted: titleEnc.data,
    isPinned: false
  });

  const handler = createGetEntitiesHandler({
    authVerifier,
    cryptoService,
    persistenceRepository
  });

  const result = await handler({
    authorizationHeader: "Bearer test-token",
    query: { type: "memo", limit: "10" }
  });

  assert.equal(result.status, 200);
  const body = result.body as { items: Array<{ type: string }> };
  assert.equal(body.items.length, 1);
  assert.equal(body.items[0]?.type, "memo");
});
