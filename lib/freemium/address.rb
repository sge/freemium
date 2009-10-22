module Freemium
  # eventually, this should mimic ActiveMerchant's credit card object, with validation and errors, etc.
  # for now it's just a dumb (and therefore untested) data structure.
  class Address
    attr_accessor :address1, :address2, :city, :state, :zip, :country, :email, :phone_number, :ip_address

    # Allow :street to be used instead of :address1
    alias_method :street,  :address1
    alias_method :street=, :address1=

    def initialize(options = {})
      options.each do |key, value|
        setter = "#{key}="
        self.send(setter, value) if self.respond_to? setter
      end
    end
  end
end