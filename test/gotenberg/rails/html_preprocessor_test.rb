# frozen_string_literal: true

require "test_helper"

class GotenbergRailsHtmlPreprocessorTest < Minitest::Test
  def test_returns_original_html_without_display_url
    html = '<img src="/logo.png">'

    assert_equal html, Gotenberg::Rails::HtmlPreprocessor.new(html, display_url: nil).call
  end

  def test_rewrites_common_html_url_attributes
    html = <<~HTML
      <!doctype html>
      <html>
        <head>
          <link rel="stylesheet" href="/assets/application.css">
          <script src="packs/application.js"></script>
        </head>
        <body>
          <a href="/invoices/1">Invoice</a>
          <img src="../logo.png">
        </body>
      </html>
    HTML

    document = preprocess(html)

    assert_equal "https://example.com/assets/application.css", document.at_css("link")["href"]
    assert_equal "https://example.com/invoices/packs/application.js", document.at_css("script")["src"]
    assert_equal "https://example.com/invoices/1", document.at_css("a")["href"]
    assert_equal "https://example.com/logo.png", document.at_css("img")["src"]
  end

  def test_rewrites_srcset_and_css_urls
    html = <<~HTML
      <!doctype html>
      <html>
        <head>
          <style>.logo { background-image: url('/logo.svg'); }</style>
        </head>
        <body>
          <img srcset="/small.png 1x, images/large.png 2x" style="background: url(icon.png)">
        </body>
      </html>
    HTML

    document = preprocess(html)

    assert_equal(
      "https://example.com/small.png 1x, https://example.com/invoices/images/large.png 2x",
      document.at_css("img")["srcset"]
    )
    assert_includes document.at_css("img")["style"], "url(https://example.com/invoices/icon.png)"
    assert_includes document.at_css("style").content, "url('https://example.com/logo.svg')"
  end

  def test_leaves_special_urls_unchanged
    html = <<~HTML
      <!doctype html>
      <html>
        <body>
          <a href="#details">Details</a>
          <a class="email" href="mailto:test@example.com">Email</a>
          <img src="data:image/png;base64,abc">
        </body>
      </html>
    HTML

    document = preprocess(html)

    assert_equal "#details", document.at_css("a")["href"]
    assert_equal "mailto:test@example.com", document.at_css("a.email")["href"]
    assert_equal "data:image/png;base64,abc", document.at_css("img")["src"]
  end

  private

  def preprocess(html)
    Nokogiri::HTML5(
      Gotenberg::Rails::HtmlPreprocessor.new(
        html,
        display_url: "https://example.com/invoices/1"
      ).call
    )
  end
end
