import assert from "node:assert/strict";
import test from "node:test";
import { endOfDayInTimeZoneIso, normalizeApiDateTime } from "../services/api-datetime.js";

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

test("endOfDayInTimeZoneIso returns 23:59:59 of the local day", () => {
  // JST 10/10 08:00（UTC では 10/09 23:00）でも、JST の 10/10 の終わりになる
  assert.equal(
    endOfDayInTimeZoneIso(new Date("2026-10-09T23:00:00Z"), "Asia/Tokyo"),
    "2026-10-10T14:59:59.000Z"
  );
  assert.equal(
    endOfDayInTimeZoneIso(new Date("2026-10-10T14:00:00Z"), "Asia/Tokyo"),
    "2026-10-10T14:59:59.000Z"
  );
  assert.equal(
    endOfDayInTimeZoneIso(new Date("2026-10-10T12:00:00Z"), "UTC"),
    "2026-10-10T23:59:59.000Z"
  );
});

test("endOfDayInTimeZoneIso falls back to UTC for unknown time zones", () => {
  assert.equal(
    endOfDayInTimeZoneIso(new Date("2026-10-10T12:00:00Z"), "Invalid/Zone"),
    "2026-10-10T23:59:59.000Z"
  );
});
