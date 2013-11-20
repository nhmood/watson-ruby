# -*- encoding: utf-8 -*-
# [review] - Should this match same style as bin/watson?
$:.push File.expand_path("../lib", __FILE__)
require "watson/version"

Gem::Specification.new do |s|
	s.name			= 'watson-ruby'
	s.version		= Watson::VERSION 
	s.date			= '2013-11-06'

	s.authors		= ["nhmood"]
	s.email			= 'nhmood@goosecode.com'
	s.homepage		= 'http://goosecode.com/watson'

	s.summary		= "an inline issue manager"
	s.description	= "an inline issue manager with GitHub and Bitbucket support"
	
	s.license		= 'MIT'
	s.files			= `git ls-files`.split("\n").delete_if { |file| file.include?("assets/examples") } 
	s.test_files	= `git ls-files -- {test,spec,features}/*`.split("\n")
	s.executables	= `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

	s.require_paths = ["assets", "bin", "lib"]

	# Ruby Dependency
	s.required_ruby_version = '>= 2.0.0'

	# Runtime Dependencies
	s.add_runtime_dependency 'json'

	# Development Dependencies
	s.add_development_dependency 'rake'
	s.add_development_dependency 'rspec'
end


