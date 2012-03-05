module Freemium
  module Generators
    class FreemiumGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      namespace "freemium"
      source_root File.expand_path("../templates", __FILE__)

      desc "Generates a model with the given NAME (if one does not exist) with freemium " <<
           "configuration plus a migration file and freemium routes."

      hook_for :orm
    end
  end
end