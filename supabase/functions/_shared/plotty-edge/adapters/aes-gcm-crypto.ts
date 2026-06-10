import type { CryptoService, EncryptedPayload } from "../services/crypto.ts";

const encodeBase64 = (bytes: Uint8Array): string => {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
};

const decodeBase64 = (value: string): Uint8Array => {
  const binary = atob(value);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
};

const decodeBase64ToKeyBytes = (value: string): Uint8Array => {
  const bytes = decodeBase64(value);
  if (bytes.byteLength !== 32) {
    throw new Error("APP_ENCRYPTION_KEY_BASE64 must be 32 bytes (base64)");
  }
  return bytes;
};

const toArrayBuffer = (bytes: Uint8Array): ArrayBuffer => {
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
};

const importAesKey = async (keyBase64: string): Promise<CryptoKey> => {
  const rawKey = decodeBase64ToKeyBytes(keyBase64);
  return crypto.subtle.importKey("raw", toArrayBuffer(rawKey), "AES-GCM", false, ["encrypt", "decrypt"]);
};

export const createAesGcmCryptoService = (appKeyBase64: string): CryptoService => {
  const keyPromise = importAesKey(appKeyBase64);

  return {
    async encryptText(plainText: string): Promise<EncryptedPayload> {
      const ivBytes = crypto.getRandomValues(new Uint8Array(12));
      const key = await keyPromise;
      const plainBytes = new TextEncoder().encode(plainText);
      const cipherBuffer = await crypto.subtle.encrypt(
        { name: "AES-GCM", iv: ivBytes },
        key,
        plainBytes
      );

      return {
        iv: encodeBase64(ivBytes),
        data: encodeBase64(new Uint8Array(cipherBuffer))
      };
    },
    async encryptDataWithIv(plainText: string, iv: string): Promise<string> {
      const key = await keyPromise;
      const ivBytes = decodeBase64(iv);
      const plainBytes = new TextEncoder().encode(plainText);
      const cipherBuffer = await crypto.subtle.encrypt(
        { name: "AES-GCM", iv: toArrayBuffer(ivBytes) },
        key,
        plainBytes
      );
      return encodeBase64(new Uint8Array(cipherBuffer));
    },
    async decryptText(payload: EncryptedPayload): Promise<string> {
      const key = await keyPromise;
      const ivBytes = decodeBase64(payload.iv);
      const cipherBytes = decodeBase64(payload.data);
      const plainBuffer = await crypto.subtle.decrypt(
        { name: "AES-GCM", iv: toArrayBuffer(ivBytes) },
        key,
        toArrayBuffer(cipherBytes)
      );
      return new TextDecoder().decode(new Uint8Array(plainBuffer));
    }
  };
};
