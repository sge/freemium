require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'freemium'

class User < ActiveRecord::Base
  has_many :subscriptions, :as => :subscribable
end

class CouponRedemption < ActiveRecord::Base
  include Freemium::CouponRedemption
end

class Subscription < ActiveRecord::Base
  include Freemium::Subscription
  include Freemium::ManualBilling
end

class SubscriptionPlan < ActiveRecord::Base
  include Freemium::SubscriptionPlan
end

class CreditCard < ActiveRecord::Base
  include Freemium::CreditCard
end

class Coupon < ActiveRecord::Base
  include Freemium::Coupon
end

class AccountTransaction < ActiveRecord::Base
  include Freemium::Transaction
end

class SubscriptionChange < ActiveRecord::Base
  include Freemium::SubscriptionChange
end

ActiveRecord::Base.establish_connection({
  adapter: 'mysql2',
  host: '127.0.0.1',
  database: 'freemium_test',
  username: 'root',
  password: nil
})

# ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Migration.verbose = true
ActiveRecord::Migrator.migrate(File.expand_path("../../migrations",__FILE__))

module RSpec
  module Core
    class ExampleGroup
      def self.fixtures(*klasses)
        silence_warnings do
          @@fixtures = {}
        end
        klasses.each do |class_plural_name|
          info  = YAML.load_file(File.expand_path("../fixtures/#{class_plural_name}.yml",__FILE__))
          klass = class_plural_name.to_s.singularize.camelize.constantize
          info.each_pair do |obj_key,obj_attrs|
            silence_warnings do
              @@fixtures[class_plural_name] = {} unless @@fixtures.has_key?(class_plural_name)
            end
            static_obj_attrs = {}
            obj_attrs.each_pair do |k,v|
              static_obj_attrs[k] = v unless v.is_a?(String) && v.include?('<%=')
              if v.is_a?(String) && v.include?('<%=')
                obj_attrs[k] = eval(v.gsub('<%=','').gsub('%>',''))
              end
            end
            model = klass.where(static_obj_attrs).first
            unless model
              model = klass.new(obj_attrs)
              model.save! validate: false
            end
            silence_warnings do
              @@fixtures[class_plural_name][obj_key.to_sym] = model
            end
          end
          self.define_method(class_plural_name) do |obj_key|
            silence_warnings do
              @@fixtures[class_plural_name][obj_key.to_sym]
            end
          end
        end
      end
    end
  end
end

class CreditCard

  def self.sample_params
    {
      :first_name => "Santa",
      :last_name => "Claus",
      :card_type => "visa",
      :number => "4111111111111111",
      :month => 10,
      :year => (Time.now + 3.years).year,
      :verification_value => 999
    }
  end

  def self.sample
    CreditCard.new(CreditCard.sample_params)
  end
end

Freemium::FeatureSet.config_file = File.join(File.dirname(__FILE__), '/freemium_feature_sets.yml')

RSpec.configure do |config|
end

# Dir[File.expand_path('../fixtures/*.yml',__FILE__)].each do |file|
#   info = YAML.load_file(file)
#   klass = File.basename(file)
#   puts info.inspect
# end