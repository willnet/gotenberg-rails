# frozen_string_literal: true

module Gotenberg
  module Rails
    class Configuration
      attr_accessor :endpoint, :request_timeout, :open_timeout, :pdf_options, :headers

      def initialize
        @endpoint = ENV.fetch("GOTENBERG_ENDPOINT", "http://localhost:3000")
        @request_timeout = 60
        @open_timeout = 10
        @pdf_options = {}
        @headers = {}
      end
    end
  end
end
