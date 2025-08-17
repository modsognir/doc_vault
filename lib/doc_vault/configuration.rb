# frozen_string_literal: true

module DocVault
  class Configuration
    attr_reader :database_path

    def initialize
      @database_path = Dir.pwd
    end

    def database_path=(path)
      raise ArgumentError, "Database path cannot be nil" if path.nil?
      raise ArgumentError, "Database path must be a valid directory" unless Dir.exist?(path) || path == Dir.pwd

      @database_path = File.expand_path(path)
    end

    def full_database_path(db_name)
      File.join(@database_path, "#{db_name}.db")
    end
  end
end
