# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

Rake::Task["release:rubygem_push"].clear
desc "Pick up the .gem file from pkg/ and push it to Gemfury"
task "release:rubygem_push" do
  # IMPORTANT: You need to have the `fury` gem installed, and you need to be logged in.
  # Please DO READ about "impersonation", which is how you push to your company account instead
  # of your personal account!
  # https://gemfury.com/help/collaboration#impersonation
  paths = Dir.glob("#{__dir__}/pkg/*.gem")
  raise "Must have found only 1 .gem path, but found #{paths.inspect}" if paths.length != 1

  escaped_gem_path = Shellwords.escape(paths.shift)
  `fury push #{escaped_gem_path} --as=wetransfer`
end
