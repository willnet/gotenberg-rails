# frozen_string_literal: true

require "json"
require "net/http"
require "stringio"
require "uri"

module Gotenberg
  module Rails
    class Client
      HTML_PATH = "/forms/chromium/convert/html"
      URL_PATH = "/forms/chromium/convert/url"

      attr_reader :endpoint, :open_timeout, :request_timeout, :headers

      def initialize(endpoint:, open_timeout:, request_timeout:, headers: {})
        @endpoint = endpoint.to_s.delete_suffix("/")
        @open_timeout = open_timeout
        @request_timeout = request_timeout
        @headers = headers
      end

      def render_pdf(html: nil, url: nil, header_html: nil, footer_html: nil, pdf_options: {}, filename: nil, trace: nil)
        if html && url
          raise ArgumentError, "Provide either :html or :url, not both"
        elsif html
          post(HTML_PATH, html_form(html, header_html, footer_html, pdf_options), filename:, trace:)
        elsif url
          post(URL_PATH, url_form(url, header_html, footer_html, pdf_options), filename:, trace:)
        else
          raise ArgumentError, "Provide :html or :url"
        end
      end

      private

      def html_form(html, header_html, footer_html, pdf_options)
        [
          html_file(html, "index.html"),
          *header_footer_files(header_html, footer_html),
          *option_fields(pdf_options)
        ]
      end

      def url_form(url, header_html, footer_html, pdf_options)
        [
          ["url", url.to_s],
          *header_footer_files(header_html, footer_html),
          *option_fields(pdf_options)
        ]
      end

      def header_footer_files(header_html, footer_html)
        {
          "header.html" => header_html,
          "footer.html" => footer_html
        }.compact.map { |filename, content| html_file(content, filename) }
      end

      def html_file(content, filename)
        ["files", StringIO.new(content.to_s), { filename:, content_type: "text/html" }]
      end

      def option_fields(options)
        options.compact.map do |key, value|
          [camelize_option(key), encode_option(value)]
        end
      end

      def camelize_option(key)
        key.to_s.gsub(/_([a-z])/) { Regexp.last_match(1).upcase }
      end

      def encode_option(value)
        case value
        when Array, Hash
          JSON.generate(value)
        else
          value.to_s
        end
      end

      def post(path, form, filename:, trace:)
        uri = URI.join("#{endpoint}/", path.delete_prefix("/"))
        request = Net::HTTP::Post.new(uri)
        headers.each { |key, value| request[key] = value }
        request["Gotenberg-Output-Filename"] = filename if filename
        request["Gotenberg-Trace"] = trace if trace
        request.set_form(form, "multipart/form-data")

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |connection|
          connection.open_timeout = open_timeout
          connection.read_timeout = request_timeout
          connection.request(request)
        end

        return response.body if response.is_a?(Net::HTTPSuccess)

        raise ConversionError, response
      end
    end
  end
end
