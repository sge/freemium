class FreemiumMigrationGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options = {})
    runtime_args.insert(0, 'migrations')
    super
  end

  def manifest
    record do |m|
      m.migration_template "migration.rb", "db/migrate", :migration_file_name => "create_subscription_and_plan"
      %w(coupon coupon_redemption credit_card subscription subscription_plan).each do |model|
        m.template "#{model}.rb", "app/models/freemium_#{model}.rb"
      end
    end
  end
end
