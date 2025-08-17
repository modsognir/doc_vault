# frozen_string_literal: true

module DocVault
  class RetrieveDocument
    def self.call(id:, bucket:, key:)
      new(id:, bucket:, key:).call
    end

    def initialize(id:, bucket:, key:)
      @id = id
      @bucket = bucket
      @key = key
      validate_params
    end

    def call
      database = Database.new(@bucket)
      encrypted_doc = database.retrieve(@id)
      raise DocumentNotFoundError, "Document with id '#{@id}' not found" unless encrypted_doc

      decrypted_doc = Encryption.decrypt(encrypted_doc, @key)
      DocumentSerializer.deserialize(decrypted_doc)
    end

    private

    def validate_params
      raise ArgumentError, "Document ID cannot be nil or empty" if @id.nil? || @id.to_s.strip.empty?
      raise ArgumentError, "Database name cannot be nil or empty" if @bucket.nil? || @bucket.to_s.strip.empty?
      raise ArgumentError, "Encryption key cannot be nil or empty" if @key.nil? || @key.to_s.strip.empty?
    end
  end
end
