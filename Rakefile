require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rdoc/task'

task :default => :run_all
task :test => :spec

task :run_all => [:spec, :rdoc, :install] do

end

desc 'Run RSpec tests'
RSpec::Core::RakeTask.new(:spec)

desc 'Generate RDoc documentation'
RDoc::Task.new(:rdoc) do | rdoc |
  rdoc.rdoc_dir = 'doc'
  rdoc.rdoc_files.include 'lib'
end


