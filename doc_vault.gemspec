# frozen_string_literal: true

require_relative "lib/doc_vault/version"

Gem::Specification.new do |spec|
  spec.name = "doc_vault"
  spec.version = DocVault::VERSION
  spec.authors = ["Jared Fraser"]
  spec.email = ["dev@jsf.io"]

  spec.summary = "Store and retrieve encrypted documents in SQLite"
  spec.description = "Store and retrieve encrypted documents in SQLite"
  spec.homepage = "https://github.com/modsognir/doc_vault"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/modsognir/doc_vault"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sqlite3", ">= 1.6"
  spec.add_dependency "base64", "~> 0.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
