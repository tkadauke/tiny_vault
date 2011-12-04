# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
TinyVault::Application.initialize!

Dir["#{Rails.root}/lib/**/*.rb"].each do |file|
  require file
end
