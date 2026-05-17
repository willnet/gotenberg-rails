# frozen_string_literal: true

module Gotenberg
  module Rails
    class Error < StandardError; end

    class ConversionError < Error
      attr_reader :response

      def initialize(response)
        @response = response
        super("Gotenberg conversion failed with #{response.code}: #{response.body}")
      end
    end
  end
end
