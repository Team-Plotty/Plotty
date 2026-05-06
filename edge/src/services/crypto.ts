export interface EncryptedPayload {
  iv: string;
  data: string;
}

export interface CryptoService {
  encryptText(plainText: string): Promise<EncryptedPayload>;
}
