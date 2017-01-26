source "https://rubygems.org"

gem "railties", "~> 3.1.5"
gem 'actionpack', '~> 3.1.5'
gem 'activesupport', '~> 3.1.5'
gem 'rspec-rails', '>= 2.0'

gem "test-unit", "~> 3.0" if RUBY_VERSION > "2.1"

gemspec :path => '../'
