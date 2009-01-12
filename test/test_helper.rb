ENV["RAILS_ENV"] = "test"

# load the support libraries
require 'test/unit'
require 'rubygems'
require 'active_record'
require 'active_record/fixtures'
require 'action_mailer'
require 'mocha'

# establish the database connection
ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/db/database.yml'))
ActiveRecord::Base.establish_connection('active_record_merge_test')

# capture the logging
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

# load the schema
$stdout = File.open('/dev/null', 'w')
load(File.dirname(__FILE__) + "/db/schema.rb")
$stdout = STDOUT

# configure the TestCase settings
class Test::Unit::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  self.fixture_path = File.dirname(__FILE__) + '/fixtures/'
end

# disable actual email delivery
ActionMailer::Base.delivery_method = :test

# load the code-to-be-tested
ActiveSupport::Dependencies.load_paths << File.dirname(__FILE__) + '/../lib' # for ActiveSupport autoloading
require File.dirname(__FILE__) + '/../init'

# load the ActiveRecord models
require File.dirname(__FILE__) + '/db/models'

# some test credit_card params
class FreemiumCreditCard
  def self.sample_params
    {
      :first_name => "Santa",
      :last_name => "Claus",
      :card_type => "visa",
      :number => "4111111111111111",
      :month => 10,
      :year => 2010,
      :verification_value => 999
    }
  end
  
  def self.sample
    FreemiumCreditCard.new(FreemiumCreditCard.sample_params)
  end
end

Freemium::FeatureSet.config_file = File.dirname(__FILE__) + '/freemium_feature_sets.yml'
