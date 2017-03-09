#!/usr/bin/env rackup

require_relative 'config/environment'

require 'rack/freeze'

warmup do |app|
	# Freeze all the middleware so that mutation bugs are detected.
	app.freeze
end

if RACK_ENV == :production
	# Handle exceptions in production with a error page and send an email notification:
	use Utopia::Exceptions::Handler
	use Utopia::Exceptions::Mailer
else
	# We want to propate exceptions up when running tests:
	use Rack::Freeze[Rack::ShowExceptions] unless RACK_ENV == :test
	
	# Serve the public directory in a similar way to the web server:
	use Utopia::Static, root: 'public'
end

use Rack::Freeze[Rack::Sendfile]

use Utopia::ContentLength

use Utopia::Redirection::Rewrite,
	'/' => '/wiki/index'

use Utopia::Redirection::DirectoryIndex

use Utopia::Redirection::Errors,
	404 => '/errors/file-not-found'

use Utopia::Localization,
	:default_locale => 'en',
	:locales => ['en', 'de', 'ja', 'zh'],
	:ignore => ['/_static/', '/_cache/']

use Utopia::Controller,
	cache_controllers: (RACK_ENV == :production),
	base: Utopia::Controller::Base

use Utopia::Static

# Serve dynamic content
use Utopia::Content,
	cache_templates: (RACK_ENV == :production)

run lambda { |env| [404, {}, []] }
