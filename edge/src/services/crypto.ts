export interface EncryptedPayload {
  iv: string;
  data: string;
}

export interface CryptoService {
  encryptText(plainText: string): Promise<EncryptedPayload>;
  /** 既存行の iv を共有して暗号文のみ生成する（GET 復号と iv を揃える） */
  encryptDataWithIv(plainText: string, iv: string): Promise<string>;
  decryptText(payload: EncryptedPayload): Promise<string>;
}
