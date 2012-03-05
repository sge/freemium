require 'rails'

require 'money'
require "freemium/version"
require 'freemium/address'
require 'freemium/coupon'
require 'freemium/coupon_redemption'
require 'freemium/credit_card'
require 'freemium/feature_set'
require 'freemium/manual_billing'
require 'freemium/rates'
require 'freemium/recurring_billing'
require 'freemium/response'
require 'freemium/subscription'
require 'freemium/subscription_change'
require 'freemium/subscription_plan'
require 'freemium/transaction'
require 'freemium/gateways/base'
require 'freemium/gateways/brain_tree'
require 'freemium/gateways/test'
require 'freemium/subscription_mailer'

module Freemium
  class CreditCardStorageError < RuntimeError; end

  # Lets you configure which ActionMailer class contains appropriate
  # mailings for invoices, expiration warnings, and expiration notices.
  # You'll probably want to create your own, based on lib/subscription_mailer.rb.
  mattr_accessor :mailer
  @@mailer = SubscriptionMailer

  # The gateway of choice. Default gateway is a stubbed testing gateway.
  mattr_accessor :gateway
  @@gateway = Freemium::Gateways::Test.new

  # You need to specify whether Freemium or your gateway's ARB module will control
  # the billing process. If your gateway's ARB controls the billing process, then
  # Freemium will simply try and keep up-to-date on transactions.
  def self.billing_handler=(val)
    case val
    when :manual  then FreemiumSubscription.send(:include, Freemium::ManualBilling)
    when :gateway then FreemiumSubscription.send(:include, Freemium::RecurringBilling)
    else
      raise "unknown billing_handler: #{val}"
    end
  end

  # How many days to keep an account active after it fails to pay.
  mattr_accessor :days_grace
  @@days_grace = 3

  # How many days in an initial free trial?
  mattr_accessor :days_free_trial
  @@days_free_trial = 0

  # What plan to assign to subscriptions that have expired. May be nil.
  mattr_writer :expired_plan
  def self.expired_plan
    @@expired_plan ||= (FreemiumSubscriptionPlan.find_by_redemption_key(expired_plan_key.to_s) if expired_plan_key)
  end

  # It's easier to assign a plan by it's key (so you don't get errors before you run migrations)
  # we will reset subscription_plan when we change the key
  mattr_reader :expired_plan_key
  def self.expired_plan_key=(key)
    @@expired_plan_key = key
    @@expired_plan = nil
  end

  # If you want to receive admin reports, enter an email (or list of emails) here.
  # These will be bcc'd on all SubscriptionMailer emails, and will also receive the
  # admin activity report.
  mattr_accessor :admin_report_recipients
end
