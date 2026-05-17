# frozen_string_literal: true

require "test_helper"

class GotenbergRailsTest < Minitest::Test
  def teardown
    Gotenberg::Rails.reset_configuration!
  end

  def test_has_a_version_number
    refute_nil Gotenberg::Rails::VERSION
  end

  def test_merges_default_pdf_options
    fake_client = FakeClient.new
    Gotenberg::Rails.client = fake_client
    Gotenberg::Rails.configuration.pdf_options = { print_background: true, margin_top: "1" }

    assert_equal "%PDF", Gotenberg::Rails.render_pdf(
      html: "<h1>Hello</h1>",
      pdf_options: { print_background: false }
    )
    assert_equal(
      {
        html: "<h1>Hello</h1>",
        url: nil,
        pdf_options: { print_background: false, margin_top: "1" }
      },
      fake_client.calls.first
    )
  end

  def test_preprocesses_html_with_display_url
    fake_client = FakeClient.new
    Gotenberg::Rails.client = fake_client

    Gotenberg::Rails.render_pdf(
      html: '<img src="/logo.png">',
      display_url: "https://example.com/invoices/1"
    )

    assert_includes fake_client.calls.first[:html], 'src="https://example.com/logo.png"'
  end
end
