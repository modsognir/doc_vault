# frozen_string_literal: true

require "openssl"
require "base64"

module DocVault
  class Encryption
    ALGORITHM = "AES-256-GCM"
    IV_SIZE = 12
    AUTH_TAG_SIZE = 16

    def self.encrypt(data, key)
      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.encrypt

      salt = OpenSSL::Random.random_bytes(16)
      derived_key = OpenSSL::PKCS5.pbkdf2_hmac(key, salt, 100_000, 32, OpenSSL::Digest.new("SHA256"))
      cipher.key = derived_key

      iv = cipher.random_iv
      encrypted = cipher.update(data) + cipher.final
      auth_tag = cipher.auth_tag

      combined = salt + iv + auth_tag + encrypted
      Base64.strict_encode64(combined)
    rescue OpenSSL::Cipher::CipherError
      raise EncryptionError, "Encryption failed"
    end

    def self.decrypt(encrypted_data, key)
      combined = Base64.strict_decode64(encrypted_data)

      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.decrypt

      salt = combined[0, 16]
      iv = combined[16, IV_SIZE]
      auth_tag = combined[16 + IV_SIZE, AUTH_TAG_SIZE]
      encrypted = combined[16 + IV_SIZE + AUTH_TAG_SIZE..]

      derived_key = OpenSSL::PKCS5.pbkdf2_hmac(key, salt, 100_000, 32, OpenSSL::Digest.new("SHA256"))
      cipher.key = derived_key
      cipher.iv = iv
      cipher.auth_tag = auth_tag

      cipher.update(encrypted) + cipher.final
    rescue OpenSSL::Cipher::CipherError, ArgumentError
      raise EncryptionError, "Decryption failed"
    end
  end
end
