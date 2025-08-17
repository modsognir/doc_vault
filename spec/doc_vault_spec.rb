# frozen_string_literal: true

RSpec.describe DocVault do
  let(:test_db) { "test_vault" }
  let(:document_id) { "test_document_123" }
  let(:encryption_key) { "my_secret_key" }
  let(:test_document) { "This is a test document with sensitive information." }

  after do
    # Clean up test database file
    File.delete("#{test_db}.db") if File.exist?("#{test_db}.db")
  end

  it "has a version number" do
    expect(DocVault::VERSION).not_to be nil
  end

  describe ".store and .retrieve" do
    it "stores and retrieves a document successfully" do
      DocVault.store(test_document, id: document_id, bucket: test_db, key: encryption_key)

      retrieved_document = DocVault.retrieve(document_id, bucket: test_db, key: encryption_key)

      expect(retrieved_document).to eq(test_document)
    end

    it "raises DocumentNotFoundError when document doesn't exist" do
      expect {
        DocVault.retrieve("nonexistent_id", bucket: test_db, key: encryption_key)
      }.to raise_error(DocVault::DocumentNotFoundError, "Document with id 'nonexistent_id' not found")
    end

    it "raises EncryptionError when using wrong decryption key" do
      DocVault.store(test_document, id: document_id, bucket: test_db, key: encryption_key)

      expect {
        DocVault.retrieve(document_id, bucket: test_db, key: "wrong_key")
      }.to raise_error(DocVault::EncryptionError)
    end
  end

  describe "validation" do
    it "raises ArgumentError when document is nil" do
      expect {
        DocVault.store(nil, id: document_id, bucket: test_db, key: encryption_key)
      }.to raise_error(ArgumentError, "Document cannot be nil")
    end

    it "raises ArgumentError when id is empty" do
      expect {
        DocVault.store(test_document, id: "", bucket: test_db, key: encryption_key)
      }.to raise_error(ArgumentError, "Document ID cannot be nil or empty")
    end

    it "raises ArgumentError when database name is empty" do
      expect {
        DocVault.store(test_document, id: document_id, bucket: "", key: encryption_key)
      }.to raise_error(ArgumentError, "Database name cannot be nil or empty")
    end

    it "raises ArgumentError when key is empty" do
      expect {
        DocVault.store(test_document, id: document_id, bucket: test_db, key: "")
      }.to raise_error(ArgumentError, "Encryption key cannot be nil or empty")
    end
  end

  describe "document replacement" do
    it "replaces existing document with same id" do
      original_doc = "Original document"
      updated_doc = "Updated document"

      DocVault.store(original_doc, id: document_id, bucket: test_db, key: encryption_key)
      DocVault.store(updated_doc, id: document_id, bucket: test_db, key: encryption_key)

      retrieved_document = DocVault.retrieve(document_id, bucket: test_db, key: encryption_key)

      expect(retrieved_document).to eq(updated_doc)
    end
  end

  describe "configuration" do
    after do
      DocVault.reset_configuration!
    end

    it "has default configuration" do
      expect(DocVault.configuration.database_path).to eq(Dir.pwd)
    end

    it "allows configuration via block" do
      test_path = "/tmp"

      DocVault.configure do |config|
        config.database_path = test_path
      end

      expect(DocVault.configuration.database_path).to eq(test_path)
    end

    it "allows direct configuration access" do
      test_path = "/tmp"

      DocVault.configuration.database_path = test_path

      expect(DocVault.configuration.database_path).to eq(test_path)
    end

    it "validates database path exists" do
      expect {
        DocVault.configuration.database_path = "/nonexistent/path"
      }.to raise_error(ArgumentError, "Database path must be a valid directory")
    end

    it "rejects nil database path" do
      expect {
        DocVault.configuration.database_path = nil
      }.to raise_error(ArgumentError, "Database path cannot be nil")
    end

    it "stores databases in configured path" do
      # Create a temporary directory for testing
      test_dir = File.join(Dir.tmpdir, "doc_vault_test_#{Time.now.to_i}")
      Dir.mkdir(test_dir) unless Dir.exist?(test_dir)

      begin
        DocVault.configure do |config|
          config.database_path = test_dir
        end

        DocVault.store("test content", id: "config_test", bucket: "config_db", key: "test_key")

        expected_db_path = File.join(test_dir, "config_db.db")
        expect(File.exist?(expected_db_path)).to be true

        retrieved = DocVault.retrieve("config_test", bucket: "config_db", key: "test_key")
        expect(retrieved).to eq("test content")
      ensure
        # Clean up test directory and database
        Dir.glob(File.join(test_dir, "*.db")).each { |file| File.delete(file) }
        Dir.rmdir(test_dir) if Dir.exist?(test_dir)
      end
    end
  end

  describe "file handling" do
    let(:test_file_content) { "This is test file content" }
    let(:test_filename) { "test_document.txt" }

    after do
      # Clean up any temporary files
      Dir.glob("test_file_*.txt").each { |file| File.delete(file) if File.exist?(file) }
    end

    it "stores and retrieves a File object" do
      # Create a test file
      test_file_path = "test_file_#{Time.now.to_i}.txt"
      File.write(test_file_path, test_file_content)

      file = File.open(test_file_path, "r")

      DocVault.store(file, id: "file_doc", bucket: test_db, key: encryption_key)
      file.close

      retrieved_file = DocVault.retrieve("file_doc", bucket: test_db, key: encryption_key)

      expect(retrieved_file).to be_a(Tempfile)
      expect(retrieved_file.read).to eq(test_file_content)

      retrieved_file.close
      File.delete(test_file_path)
    end

    it "stores and retrieves a Tempfile object with metadata" do
      tempfile = Tempfile.new([test_filename.gsub(".txt", ""), ".txt"])
      tempfile.write(test_file_content)
      tempfile.rewind

      # Add metadata to simulate uploaded file
      filename = test_filename
      tempfile.define_singleton_method(:original_filename) { filename }
      tempfile.define_singleton_method(:content_type) { "text/plain" }

      DocVault.store(tempfile, id: "tempfile_doc", bucket: test_db, key: encryption_key)
      tempfile.close

      retrieved_file = DocVault.retrieve("tempfile_doc", bucket: test_db, key: encryption_key)

      expect(retrieved_file).to be_a(Tempfile)
      expect(retrieved_file.read).to eq(test_file_content)
      expect(retrieved_file.original_filename).to eq(test_filename)
      expect(retrieved_file.content_type).to eq("text/plain")

      retrieved_file.close
    end

    it "preserves file extensions when creating tempfiles" do
      tempfile = Tempfile.new(["test", ".pdf"])
      tempfile.write("PDF content")
      tempfile.rewind

      tempfile.define_singleton_method(:original_filename) { "document.pdf" }

      DocVault.store(tempfile, id: "pdf_doc", bucket: test_db, key: encryption_key)
      tempfile.close

      retrieved_file = DocVault.retrieve("pdf_doc", bucket: test_db, key: encryption_key)

      expect(File.extname(retrieved_file.path)).to eq(".pdf")
      expect(retrieved_file.original_filename).to eq("document.pdf")

      retrieved_file.close
    end

    it "raises ArgumentError for unsupported document types" do
      expect {
        DocVault.store(123, id: "invalid_doc", bucket: test_db, key: encryption_key)
      }.to raise_error(ArgumentError, "Document must be a String, File, or Tempfile")

      expect {
        DocVault.store([], id: "invalid_doc", bucket: test_db, key: encryption_key)
      }.to raise_error(ArgumentError, "Document must be a String, File, or Tempfile")
    end
  end
end
