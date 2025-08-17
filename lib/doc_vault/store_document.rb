# frozen_string_literal: true

module DocVault
  class StoreDocument
    def self.call(document:, id:, bucket:, key:)
      new(document:, id:, bucket:, key:).call
    end

    def initialize(document:, id:, bucket:, key:)
      @document = document
      @id = id
      @bucket = bucket
      @key = key
      validate_params
    end

    def call
      database = Database.new(@bucket)
      serialized_doc = DocumentSerializer.serialize(@document)
      encrypted_doc = Encryption.encrypt(serialized_doc, @key)
      database.store(@id, encrypted_doc)
    end

    private

    def validate_params
      raise ArgumentError, "Document cannot be nil" if @document.nil?
      raise ArgumentError, "Document ID cannot be nil or empty" if @id.nil? || @id.to_s.strip.empty?
      raise ArgumentError, "Database name cannot be nil or empty" if @bucket.nil? || @bucket.to_s.strip.empty?
      raise ArgumentError, "Encryption key cannot be nil or empty" if @key.nil? || @key.to_s.strip.empty?

      unless @document.is_a?(String) || @document.is_a?(File) || @document.is_a?(Tempfile)
        raise ArgumentError, "Document must be a String, File, or Tempfile"
      end
    end
  end
end
