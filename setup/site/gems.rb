# frozen_string_literal: true

source 'https://rubygems.org'

group :preload do
	gem 'utopia', '~> $UTOPIA_VERSION'
	# gem 'utopia-gallery'
	# gem 'utopia-analytics'
	
	gem 'variant'
end

gem 'rake'
gem 'bake'
gem 'bundler'
gem 'rack-test'

group :development do
	gem 'guard-falcon', require: false
	gem 'guard-rspec', require: false
	
	gem 'rspec'
	gem 'covered'
	
	gem 'async-rspec'
	gem 'benchmark-http'
end

group :production do
	gem 'falcon'
end
