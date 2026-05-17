# frozen_string_literal: true

require "nokogiri"
require "uri"

module Gotenberg
  module Rails
    class HtmlPreprocessor
      URL_ATTRIBUTES = %w[action href poster src].freeze
      DATA_URL_ATTRIBUTES = {
        "object" => %w[data]
      }.freeze
      SRCSET_ATTRIBUTES = %w[srcset].freeze
      SKIPPED_SCHEMES = %w[cid data javascript mailto tel].freeze
      CSS_URL_PATTERN = /url\(\s*(['"]?)([^'")]+)\1\s*\)/i

      attr_reader :html, :display_url

      def initialize(html, display_url:)
        @html = html.to_s
        @display_url = display_url
      end

      def call
        return html if display_url.nil? || display_url.to_s.empty?

        document = Nokogiri::HTML5(html)
        base_url = document.at_css("base[href]")&.[]("href") || display_url

        preprocess_url_attributes(document, base_url)
        preprocess_srcset_attributes(document, base_url)
        preprocess_css_urls(document, base_url)

        document.to_html
      end

      private

      def preprocess_url_attributes(document, base_url)
        URL_ATTRIBUTES.each do |attribute|
          document.css("[#{attribute}]").each do |node|
            node[attribute] = absolute_url(node[attribute], base_url)
          end
        end

        DATA_URL_ATTRIBUTES.each do |selector, attributes|
          attributes.each do |attribute|
            document.css("#{selector}[#{attribute}]").each do |node|
              node[attribute] = absolute_url(node[attribute], base_url)
            end
          end
        end
      end

      def preprocess_srcset_attributes(document, base_url)
        SRCSET_ATTRIBUTES.each do |attribute|
          document.css("[#{attribute}]").each do |node|
            node[attribute] = absolutize_srcset(node[attribute], base_url)
          end
        end
      end

      def preprocess_css_urls(document, base_url)
        document.css("[style]").each do |node|
          node["style"] = absolutize_css_urls(node["style"], base_url)
        end

        document.css("style").each do |node|
          node.content = absolutize_css_urls(node.content, base_url)
        end
      end

      def absolutize_srcset(value, base_url)
        value.to_s.split(",").map do |candidate|
          url, descriptor = candidate.strip.split(/\s+/, 2)
          [absolute_url(url, base_url), descriptor].compact.join(" ")
        end.join(", ")
      end

      def absolutize_css_urls(value, base_url)
        value.to_s.gsub(CSS_URL_PATTERN) do
          quote = Regexp.last_match(1)
          url = Regexp.last_match(2)
          "url(#{quote}#{absolute_url(url, base_url)}#{quote})"
        end
      end

      def absolute_url(value, base_url)
        url = value.to_s.strip
        return value if url.empty? || url.start_with?("#") || skipped_scheme?(url)

        URI.join(base_url, url).to_s
      rescue URI::InvalidURIError
        value
      end

      def skipped_scheme?(url)
        scheme = URI.parse(url).scheme
        scheme && SKIPPED_SCHEMES.include?(scheme.downcase)
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
