# frozen_string_literal: true

require "test_helper"

class GotenbergRailsClientTest < Minitest::Test
  def test_requires_html_or_url
    client = new_client

    assert_raises(ArgumentError) { client.render_pdf }
    assert_raises(ArgumentError) { client.render_pdf(html: "<p>x</p>", url: "https://example.com") }
  end

  def test_builds_html_request
    request = capture_request do
      new_client.render_pdf(
        html: "<h1>Hello</h1>",
        pdf_options: { print_background: true, fail_on_http_status_codes: [499, 599] },
        filename: "hello",
        trace: "trace-1"
      )
    end

    assert_equal "/forms/chromium/convert/html", request.uri.path
    assert_equal "hello", request["Gotenberg-Output-Filename"]
    assert_equal "trace-1", request["Gotenberg-Trace"]

    fields = request.instance_variable_get(:@body_data)
    assert_equal "files", fields[0][0]
    assert_equal "<h1>Hello</h1>", fields[0][1].read
    assert_equal({ filename: "index.html", content_type: "text/html" }, fields[0][2])
    assert_includes fields, ["printBackground", "true"]
    assert_includes fields, ["failOnHttpStatusCodes", "[499,599]"]
  end

  def test_builds_url_request
    request = capture_request do
      new_client.render_pdf(url: "https://example.com", pdf_options: { wait_delay: "2s" })
    end

    assert_equal "/forms/chromium/convert/url", request.uri.path

    fields = request.instance_variable_get(:@body_data)
    assert_includes fields, ["url", "https://example.com"]
    assert_includes fields, ["waitDelay", "2s"]
  end

  private

  def new_client
    Gotenberg::Rails::Client.new(
      endpoint: "http://gotenberg.test:3000",
      open_timeout: 1,
      request_timeout: 1
    )
  end

  def capture_request
    @captured_request = nil
    singleton = class << Net::HTTP; self; end
    original = Net::HTTP.method(:start)
    previous_verbose = $VERBOSE
    $VERBOSE = nil

    singleton.define_method(:start, fake_http_start)
    yield
    @captured_request
  ensure
    singleton.define_method(:start, original) if original
    $VERBOSE = previous_verbose
  end

  def fake_http_start
    test = self

    lambda do |_host, _port, _options, &block|
      connection = Object.new
      connection.define_singleton_method(:open_timeout=) { |_value| }
      connection.define_singleton_method(:read_timeout=) { |_value| }
      connection.define_singleton_method(:request) do |request|
        test.instance_variable_set(:@captured_request, request)
        FakeHTTPSuccess.new("%PDF")
      end
      block.call(connection)
    end
  end
end
