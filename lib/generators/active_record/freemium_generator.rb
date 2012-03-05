require 'rails/generators/active_record'
require 'generators/freemium/orm_helpers'

module ActiveRecord
  module Generators
    class FreemiumGenerator < ActiveRecord::Generators::Base
      argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"

      include Freemium::Generators::OrmHelpers
      source_root File.expand_path("../templates", __FILE__)

      def copy_freemium_migration
        migration_template "migrations/#{table_name}.rb", "db/migrate/freemium_create_#{table_name}"
      end

      def generate_model
        invoke "active_record:model", [name], :migration => false unless model_exists? && behavior == :invoke
      end

      def inject_freemium_content
        inject_into_class(model_path, class_name, model_contents + <<CONTENT) if model_exists?
# Setup accessible (or protected) attributes for your model
include Freemium::#{class_name}
CONTENT
      end
    end
  end
end