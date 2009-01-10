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

#raise SubscriptionCreditCard.card_companies.inspect

#raise (SubscriptionCreditCard.methods - ActiveRecord::Base.methods).sort.inspect