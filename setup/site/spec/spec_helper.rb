# frozen_string_literal: true

ENV['UTOPIA_ENV'] ||= 'test'

require 'bundler/setup'
require 'covered/rspec'
require 'utopia'

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = '.rspec_status'

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
