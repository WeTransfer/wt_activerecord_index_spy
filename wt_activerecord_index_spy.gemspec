# frozen_string_literal: true

require_relative "lib/wt_activerecord_index_spy/version"

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  spec.name          = "wt_activerecord_index_spy"
  spec.version       = WtActiverecordIndexSpy::VERSION
  spec.authors       = ["Fabio Perrella"]
  spec.email         = ["fabio.perrella@gmail.com"]

  spec.summary       = "It checks if queries use an index"
  spec.description   = "It uses activerecord's notifications to run an explain" \
  " query on each query that uses a WHERE statement"
  spec.homepage      = "https://github.com/fabioperrella/wt_activerecord_index_spy"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fabioperrella/wt_activerecord_index_spy"
  spec.metadata["changelog_uri"] = "https://github.com/fabioperrella/wt_activerecord_index_spy/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activerecord", "~> 6.0"
  spec.add_dependency "activesupport", "~> 6.0"
  spec.add_dependency "rspec", "~> 3.0"

  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "gemfury"
  spec.add_development_dependency "mysql2"
  # for active_record 4
  # spec.add_development_dependency "pg", "~> 0.15"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry-byebug"
end
# rubocop:enable Metrics/BlockLength
