# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rowr/version'

Gem::Specification.new do |spec|
  spec.name          = "rowr"
  spec.version       = Rowr::VERSION
  spec.authors       = ["Luke Aeschleman", "Jason Casden"]
  spec.email         = ["lukeaeschleman@gmail.com", "casden@gmail.com"]

  spec.summary       = "The Really Old Website Refactorer"
  spec.description   = "Refactors pieces of old websites so they can be hosted again or archived."
  spec.homepage      = "https://github.com/UNC-Libraries/ROWR"
  spec.license       = "Apache-2.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  #if spec.respond_to?(:metadata)
    #spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  #else
    #raise "RubyGems 2.0 or newer is required to protect against " \
      #"public gem pushes."
  #end

  spec.files         = Dir.glob("{bin,lib,exe}/**/*") + %w(LICENSE README.md CODE_OF_CONDUCT.md)
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'rubyzip', '~> 1.2.1'
  spec.add_runtime_dependency 'slop', '~> 4.6.0'
  spec.add_runtime_dependency 'thor', '~> 0.19'
  spec.add_runtime_dependency 'tty-prompt', '~> 0.13.2'
  spec.add_runtime_dependency 'faraday', '~> 0.13.1'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 13.0.1'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
