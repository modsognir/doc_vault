# DocVault

NOTE: THIS IS IN-DEVELOPMENT SOFTWARE, PLEASE DO NOT USE FOR ANYTHING SENSITIVE

DocVault is a Ruby gem that provides a simple interface for storing and retrieving encrypted data or files in one or multiple SQLite databases.

This gem is useful for ephemeral storage of sensitive data in text or file format that needs to be readily accessible. It enables seperation of data and per-user encryption keys. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'doc_vault'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install doc_vault
```

## Usage

### Basic Usage

Store a document:

```ruby
require 'doc_vault'

# Store a document
DocVault.store(
  "This is my secret document",
  id: "document_123",
  bucket: "my_database",
  key: "my_encryption_key"
)
```

Retrieve a document:

```ruby
# Retrieve the document
document = DocVault.retrieve(
  "document_123",
  bucket: "my_database", 
  key: "my_encryption_key"
)

puts document # => "This is my secret document"
```

### Multiple Databases

You can organize documents across different databases:

```ruby
# Store in different databases
DocVault.store("Personal note", id: "note1", bucket: "personal", key: "personal_key")
DocVault.store("Work document", id: "doc1", bucket: "work", key: "work_key")

# Retrieve from specific databases
personal_note = DocVault.retrieve("note1", bucket: "personal", key: "personal_key")
work_doc = DocVault.retrieve("doc1", bucket: "work", key: "work_key")
```

### File Storage

DocVault can store and retrieve File and Tempfile objects while preserving metadata:

```ruby
# Store a File object
file = File.open("document.pdf", "rb")
DocVault.store(file, id: "pdf_doc", bucket: "files", key: "file_key")
file.close

# Retrieve returns a Tempfile with the same content
retrieved_file = DocVault.retrieve("pdf_doc", bucket: "files", key: "file_key")
puts retrieved_file.class # => Tempfile
puts retrieved_file.read  # => Original PDF content

# Store a Tempfile - upload is a JPEG File object
DocVault.store(upload, id: "photo", bucket: "uploads", key: "upload_key")
upload.close

# Retrieve with preserved metadata
photo = DocVault.retrieve("photo", bucket: "uploads", key: "upload_key")
puts photo.original_filename # => "photo.jpg"
puts photo.content_type      # => "image/jpeg"
puts File.extname(photo.path) # => ".jpg"
```

### Document Updates

Documents with the same ID will be replaced:

```ruby
# Store initial document
DocVault.store("Version 1", id: "doc", bucket: "db", key: "key")

# Update the document
DocVault.store("Version 2", id: "doc", bucket: "db", key: "key")

# Retrieve returns the latest version
doc = DocVault.retrieve("doc", bucket: "db", key: "key")
puts doc # => "Version 2"
```

### Error Handling

DocVault provides specific error types for different failure scenarios:

```ruby
begin
  DocVault.retrieve("nonexistent", bucket: "db", key: "key")
rescue DocVault::DocumentNotFoundError => e
  puts "Document not found: #{e.message}"
end

begin
  DocVault.retrieve("doc_id", bucket: "db", key: "wrong_key")
rescue DocVault::EncryptionError => e
  puts "Decryption failed: #{e.message}"
end

begin
  DocVault.store("", id: "", bucket: "db", key: "key")
rescue ArgumentError => e
  puts "Invalid arguments: #{e.message}"
end
```

### Configuration

You can configure where DocVault stores its database files:

```ruby
# Configure database path using a block
DocVault.configure do |config|
  config.database_path = "/path/to/your/databases"
end

# Or configure directly
DocVault.configuration.database_path = "/path/to/your/databases"
```

## Security

- Documents are encrypted using AES-256-GCM
- SQLite databases are created locally and can be secured using standard file system permissions
- Database files can be culled with standard file retention tools

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/modsognir/doc_vault.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
