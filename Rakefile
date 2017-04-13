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

desc "Tag repo (after committing changes and bumping version)"
task :tag do
  sh <<-eos, verbose: false
set -e
echo "# get version"
new_version=$(perl -nle 'last if /^\\s*s\\.version\\s*=\\s*(["'\\''])(.+?)\\1/ && print $2' marchex_helpers.gemspec)
echo "# create tag ${new_version}"
git tag -a ${new_version} -m "marchex_helpers version ${new_version}"
echo "# push tag"
git push origin ${new_version}
eos
end
