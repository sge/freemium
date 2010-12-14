class SubscriptionMailer < ActionMailer::Base
  prepend_view_path(File.dirname(__FILE__))

   default :from => 'billing@example.com',
           :return_path => 'no-reply@example.com'

  def invoice(transaction)
    @amount = transaction.amount
    @subscription = transaction.subscription
    mail(:to => transaction.subscription.subscribable.email,
         :bcc => Freemium.admin_report_recipients,
         :subject => "Your invoice")
  end

  def expiration_warning(subscription)
    @subscription = subscription
    mail(:to => subscription.subscribable.email,
         :bcc => Freemium.admin_report_recipients,
         :subject => "Your subscription is set to expire")
  end

  def expiration_notice(subscription)
    @subscription = subscription
    mail(:to => subscription.subscribable.email,
         :bcc => Freemium.admin_report_recipients,
         :subject => "Your subscription has expired")
  end
  
  def admin_report(transactions)
    @amount_charged       = transactions.select{|t| t.success?}.collect{|t| t.amount}.sum
    @transactions = transactions
    @amount_charged = @amount_charged
    mail(:to => Freemium.admin_report_recipients,
         :subject => "Billing report (#{@amount_charged} charged)")
  end  
end
