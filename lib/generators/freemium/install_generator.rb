require 'securerandom'

module Freemium
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc "Creates a Freemium initializer and copy locale files to your application."
      class_option :orm

      def copy_initializer
        template "freemium.rb", "config/initializers/freemium.rb"
      end

      def copy_feature_sets
        template "freemium_feature_sets.yml", "config/freemium_feature_sets.yml"
      end

      def copy_locale
        copy_file "../../../config/locales/en.yml", "config/locales/freemium.en.yml"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end