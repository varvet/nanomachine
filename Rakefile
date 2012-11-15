begin
  require "bundler/gem_tasks"
rescue LoadError
  # bundler not required
end

begin
  require "yard"
  YARD::Rake::YardocTask.new("yard:doc") do |task|
    task.options = ["--no-stats"]
  end

  desc "List undocumented methods and constants"
  task "yard:stats" do
    YARD::CLI::Stats.run("--list-undoc")
  end

  desc "Generate documentation and show documentation stats"
  task :yard => ["yard:doc", "yard:stats"]
rescue LoadError
  puts "WARN: YARD not available. You may install documentation dependencies via bundler."
end

desc "Start an IRB session with Nanomachine loaded"
task :console do
  exec "irb", "-Ilib", "-rnanomachine"
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new do |spec|
  spec.ruby_opts = ["-W"]
end

task :default => :spec
