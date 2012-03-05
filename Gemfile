source "http://rubygems.org"

gem "rails", "~> 3.1.3"
gem "sqlite3-ruby", :require => "sqlite3"
gem "money"

# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.

group :test do
  gem "autotest"
end

group :development do
  gem "autotest"
  gem "bundler", "~> 1.1.rc.8"
  gem "jeweler"
end

group :test, :development do
  gem 'ruby-debug-base19', "~>0.11.26"
  gem 'ruby-debug19',"~>0.11.6", :require => 'ruby-debug'
  gem 'rspec-rails'
end