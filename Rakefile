# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

TinyVault::Application.load_tasks

begin
  require 'i18n_tools/tasks'
rescue LoadError
end
