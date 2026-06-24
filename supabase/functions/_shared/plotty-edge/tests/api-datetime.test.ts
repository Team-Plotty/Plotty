import assert from "node:assert/strict";
import test from "node:test";
import { normalizeApiDateTime } from "../services/api-datetime.ts";

test("normalizeApiDateTime converts offset ISO to UTC Z", () => {
  assert.equal(
    normalizeApiDateTime("2026-06-17T23:59:59+09:00"),
    "2026-06-17T14:59:59.000Z"
  );
  assert.equal(
    normalizeApiDateTime("2026-06-17T14:59:59+00:00"),
    "2026-06-17T14:59:59.000Z"
  );
});
