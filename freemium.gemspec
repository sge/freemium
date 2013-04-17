# -*- encoding: utf-8 -*-
require File.expand_path('../lib/freemium/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = "freemium"
  gem.summary = %Q{Subscription Saas}
  gem.description = %Q{Subscription Saas, tests are green. Needs some refactoring.}
  gem.email = "eagle.anton@gmail.com"
  gem.homepage = "http://github.com/xn/freemium"
  gem.authors = ["Anton Oryol","xn"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  spec.add_runtime_dependency 'jabber4r', '> 0.1'
  #  spec.add_development_dependency 'rspec', '> 1.2.3'
  # gem.add_dependency "rails", "4.0.0.beta1"
  gem.add_dependency 'activerecord', '4.0.0.beta1'
  gem.add_dependency "money"
  gem.add_development_dependency 'rspec'
  # gem.add_development_dependency "rspec-rails"
  gem.add_development_dependency "bundler"
  gem.add_development_dependency 'debugger'
  # gem.add_development_dependency 'ruby-debug-base19', "~>0.11.26"
  # gem.add_development_dependency 'ruby-debug19',"~>0.11.6"
  # gem.add_development_dependency 'rspec-rails', '~>2.0'
  gem.add_development_dependency "autotest"
  gem.add_development_dependency "mysql2"
  gem.add_development_dependency "bundler"
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]
  gem.version       = Freemium::VERSION
end
