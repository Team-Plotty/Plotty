/** API レスポンスの日時を UTC ISO-8601（末尾 Z）に揃える */
export const normalizeApiDateTime = (value: string): string => {
  const millis = Date.parse(value);
  if (Number.isNaN(millis)) {
    return value;
  }
  return new Date(millis).toISOString();
};

export const normalizeApiDateTimeNullable = (value: string | null): string | null => {
  if (value === null) {
    return null;
  }
  return normalizeApiDateTime(value);
};

/** timeZone での壁時計の値を UTC とみなしたミリ秒と、実際の UTC ミリ秒の差（= その時点の UTC オフセット） */
const timeZoneOffsetMillis = (date: Date, timeZone: string): number => {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit"
  }).formatToParts(date);
  const value = (type: Intl.DateTimeFormatPartTypes): number =>
    Number(parts.find((part) => part.type === type)?.value ?? 0);
  const wallClockAsUtc = Date.UTC(
    value("year"),
    value("month") - 1,
    value("day"),
    value("hour"),
    value("minute"),
    value("second")
  );
  return wallClockAsUtc - Math.floor(date.getTime() / 1000) * 1000;
};

/**
 * timeZone での「baseDate の日の 23:59:59」を UTC ISO で返す。
 * 日付のみの締切の埋め値。UTC で 23:59 にすると日本時間では翌朝 8:59 になり日付がずれるため。
 */
export const endOfDayInTimeZoneIso = (baseDate: Date, timeZone: string): string => {
  let zone = timeZone;
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: zone });
  } catch {
    zone = "UTC";
  }
  const localNow = new Date(baseDate.getTime() + timeZoneOffsetMillis(baseDate, zone));
  const endOfLocalDayAsUtc = Date.UTC(
    localNow.getUTCFullYear(),
    localNow.getUTCMonth(),
    localNow.getUTCDate(),
    23,
    59,
    59
  );
  const offset = timeZoneOffsetMillis(new Date(endOfLocalDayAsUtc), zone);
  return new Date(endOfLocalDayAsUtc - offset).toISOString();
};
