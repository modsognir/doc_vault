# frozen_string_literal: true

require "json"
require "tempfile"

module DocVault
  class DocumentSerializer
    def self.serialize(document)
      case document
      when File, Tempfile
        serialize_file(document)
      when String
        serialize_string(document)
      else
        raise ArgumentError, "Document must be a String, File, or Tempfile"
      end
    end

    def self.deserialize(data)
      parsed = JSON.parse(data)

      case parsed["type"]
      when "file"
        deserialize_file(parsed)
      when "string"
        parsed["content"]
      else
        raise ArgumentError, "Unknown document type: #{parsed["type"]}"
      end
    rescue JSON::ParserError
      raise ArgumentError, "Invalid serialized document data"
    end

    class << self
      private

      def serialize_file(file)
        file.rewind
        content = file.read
        file.rewind

        metadata = {
          type: "file",
          content: Base64.strict_encode64(content),
          original_filename: file.respond_to?(:original_filename) ? file.original_filename : nil,
          content_type: file.respond_to?(:content_type) ? file.content_type : nil,
          path: file.respond_to?(:path) ? file.path : nil,
          size: content.length
        }

        JSON.generate(metadata)
      end

      def serialize_string(string)
        JSON.generate({
          type: "string",
          content: string
        })
      end

      def deserialize_file(parsed)
        tempfile = Tempfile.new(["doc_vault", extract_extension(parsed)])
        tempfile.binmode
        tempfile.write(Base64.strict_decode64(parsed["content"]))
        tempfile.rewind

        # Add metadata as singleton methods if available
        if parsed["original_filename"]
          tempfile.define_singleton_method(:original_filename) { parsed["original_filename"] }
        end

        if parsed["content_type"]
          tempfile.define_singleton_method(:content_type) { parsed["content_type"] }
        end

        tempfile
      end

      def extract_extension(parsed)
        return "" unless parsed["original_filename"] || parsed["path"]

        filename = parsed["original_filename"] || parsed["path"]
        File.extname(filename)
      end
    end
  end
end
