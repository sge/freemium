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