# frozen_string_literal: true

require "active_support/core_ext/hash/except"
require_relative "rails/client"
require_relative "rails/configuration"
require_relative "rails/error"
require_relative "rails/html_preprocessor"
require_relative "rails/renderer"
require_relative "rails/version"

require_relative "rails/railtie" if defined?(::Rails::Railtie)

module Gotenberg
  module Rails
    class << self
      attr_writer :configuration, :client

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield configuration
      end

      def client
        @client ||= Client.new(
          endpoint: configuration.endpoint,
          open_timeout: configuration.open_timeout,
          request_timeout: configuration.request_timeout,
          headers: configuration.headers
        )
      end

      def render_pdf(html: nil, url: nil, display_url: nil, pdf_options: {}, **options)
        merged_options = configuration.pdf_options.merge(pdf_options || {})
        html = HtmlPreprocessor.new(html, display_url:).call if html

        client.render_pdf(html:, url:, pdf_options: merged_options, **options)
      end

      def reset_configuration!
        @configuration = Configuration.new
        @client = nil
      end
    end
  end
end
