class User < ActiveRecord::Base
  has_many :subscriptions, :as => :subscribable
end

class Subscription < ActiveRecord::Base
  include Freemium::Subscription
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

class SubscriptionCoupon < ActiveRecord::Base
  include Freemium::SubscriptionCoupon
end
