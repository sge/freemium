class User < ActiveRecord::Base
  has_many :subscriptions, :as => :subscribable
end

class Subscription < ActiveRecord::Base
  include Freemium::Subscription
end

class SubscriptionPlan < ActiveRecord::Base
  include Freemium::SubscriptionPlan
end