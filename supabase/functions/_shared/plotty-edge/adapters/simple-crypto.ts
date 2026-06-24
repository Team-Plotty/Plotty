import type { CryptoService, EncryptedPayload } from "../services/crypto.ts";

const encodeBase64 = (text: string): string => {
  const bytes = new TextEncoder().encode(text);
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
};

export const createSimpleCryptoService = (): CryptoService => ({
  async encryptText(plainText: string): Promise<EncryptedPayload> {
    const iv = crypto.randomUUID().replaceAll("-", "").slice(0, 16);
    return {
      iv,
      data: await this.encryptDataWithIv(plainText, iv)
    };
  },
  async encryptDataWithIv(plainText: string, iv: string): Promise<string> {
    void iv;
    return encodeBase64(plainText);
  },
  async decryptText(payload: EncryptedPayload): Promise<string> {
    const binary = atob(payload.data);
    const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
    return new TextDecoder().decode(bytes);
  }
});
