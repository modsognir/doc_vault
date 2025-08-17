# frozen_string_literal: true

require_relative "doc_vault/version"
require_relative "doc_vault/configuration"
require_relative "doc_vault/database"
require_relative "doc_vault/encryption"
require_relative "doc_vault/document_serializer"
require_relative "doc_vault/store_document"
require_relative "doc_vault/retrieve_document"
require "sqlite3"

module DocVault
  class Error < StandardError; end

  class DatabaseError < Error; end

  class EncryptionError < Error; end

  class DocumentNotFoundError < Error; end

  def self.store(document, id:, bucket:, key:)
    StoreDocument.call(document:, id:, bucket:, key:)
  end

  def self.retrieve(id, bucket:, key:)
    RetrieveDocument.call(id:, bucket:, key:)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset_configuration!
    @configuration = Configuration.new
  end
end
