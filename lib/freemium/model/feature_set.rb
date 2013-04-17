module Freemium
  class FeatureSet

    def initialize(hash = {})
      hash.each do |key, value|
        self.class.class_eval { attr_accessor key.intern }
        self.send("#{key}=", value)
      end
    end
  
    def method_missing(method, *args, &block)
      # forward named routes
      if method.to_s.include? '?'
        send(method.to_s[0..-2], *args, &block)
      else
        super
      end
    end
 
    def self.find(id)
      self.feature_sets[id.to_s]
    end
 
    protected

    cattr_accessor :config_file
    def self.config_file
      @@config_file ||= File.join(RAILS_ROOT, 'config', 'freemium_feature_sets.yml')
    end

    cattr_accessor :feature_sets
    self.feature_sets = nil
 
    def self.feature_sets
      if @@feature_sets.nil?
        @@feature_sets = {}
        YAML::load(File.read(self.config_file)).each do |features| 
          feature_set = FeatureSet.new(features)
          @@feature_sets[feature_set.id] = feature_set
        end
      end
      @@feature_sets
    end
  end
end