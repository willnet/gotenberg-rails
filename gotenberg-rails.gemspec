# frozen_string_literal: true

require_relative "lib/gotenberg/rails/version"

Gem::Specification.new do |spec|
  spec.name = "gotenberg-rails"
  spec.version = Gotenberg::Rails::VERSION
  spec.authors = ["Shinichi Maeshima"]
  spec.email = ["netwillnet@gmail.com"]

  spec.summary = "Render Rails HTML as PDFs with Gotenberg."
  spec.description = "A small Rails renderer and Ruby API for converting HTML or URLs to PDF using Gotenberg."
  spec.homepage = "https://github.com/willnet/gotenberg-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*", "LICENSE", "README.md"]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", ">= 7.2"
  spec.add_dependency "activesupport", ">= 7.2"
  spec.add_dependency "nokogiri", ">= 1.8.5"

  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "rake", ">= 13.0"
end
