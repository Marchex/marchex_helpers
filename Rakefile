# require "bundler/setup"

task :default => [:list]

desc "List all the tasks."
task :list do
    puts "Tasks: \n- #{Rake::Task.tasks.join("\n- ")}"
end

desc "Check for (and resolve) required dependencies."
task :check do
  sh "bundle check || bundle install"
end

desc "Run spec tests."
task :spec do
    Rake::Task[:check].execute
    sh "bundle exec rspec spec"
end

desc "Run unit tests."
task :unit do
  Rake::Task[:spec].execute
end

desc "Build gem."
task :build do
  sh "gem build marchex_helpers.gemspec"
end
