source "https://rubygems.org"

gem "railties", "~> 3.0.15"
gem 'actionpack', '~> 3.0.15'
gem 'activesupport', '~> 3.0.15'
gem 'rspec-rails', '>= 2.0'

gem "test-unit", "~> 3.0" if RUBY_VERSION > "2.1"

gemspec :path => '../'
