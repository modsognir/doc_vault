# frozen_string_literal: true

require "sqlite3"

module DocVault
  class Database
    def initialize(db_name)
      @db_name = db_name
      @db_path = DocVault.configuration.full_database_path(db_name)
      create_table_if_not_exists
    end

    def store(id, encrypted_document)
      result = db.execute("INSERT OR REPLACE INTO documents (id, content) VALUES (?, ?)", [id, encrypted_document])
      id if result
    rescue SQLite3::Exception => e
      raise DatabaseError, "Failed to store document: #{e.message}"
    end

    def retrieve(id)
      result = db.execute("SELECT content FROM documents WHERE id = ?", [id])
      result.empty? ? nil : result[0][0]
    rescue SQLite3::Exception => e
      raise DatabaseError, "Failed to retrieve document: #{e.message}"
    end

    private

    def db
      @db ||= SQLite3::Database.new(@db_path)
    end

    def create_table_if_not_exists
      db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS documents (
          id TEXT PRIMARY KEY,
          content TEXT NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      SQL
    rescue SQLite3::Exception => e
      raise DatabaseError, "Failed to create table: #{e.message}"
    end
  end
end
