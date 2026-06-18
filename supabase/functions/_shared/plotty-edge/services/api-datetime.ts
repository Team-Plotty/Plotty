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
