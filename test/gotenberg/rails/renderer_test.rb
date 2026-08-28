# frozen_string_literal: true

require "test_helper"
require "action_controller"

class GotenbergRailsRendererTest < Minitest::Test
  def teardown
    Gotenberg::Rails.reset_configuration!
  end

  def test_passes_header_and_footer_separately_from_pdf_options
    Gotenberg::Rails::Renderer.register
    controller = fake_controller
    controller.extend(ActionController::Renderers)
    fake_client = FakeClient.new
    Gotenberg::Rails.client = fake_client
    options = {
      header_html: "<html><body>Header</body></html>",
      footer_html: "<html><body>Footer</body></html>",
      print_background: true
    }
    render_options = { template: "invoices/show", filename: "invoice.pdf" }

    controller._render_with_renderer_gotenberg_pdf(options, render_options)

    captured_options = fake_client.calls.first
    assert_includes captured_options.delete(:html), "<body>Invoice</body>"
    assert_equal(
      {
        url: nil,
        header_html: "<html><body>Header</body></html>",
        footer_html: "<html><body>Footer</body></html>",
        pdf_options: { print_background: true },
        filename: "invoice.pdf"
      },
      captured_options
    )
    assert_equal({ template: "invoices/show", formats: [:html] }, controller.render_options)
    assert_equal({ filename: "invoice.pdf", type: "application/pdf", disposition: "attachment" }, controller.send_options)
    assert_equal "%PDF", controller.sent_data
    assert_includes options, :header_html
    assert_includes options, :footer_html
  end

  private

  def fake_controller
    controller = Object.new
    request = Struct.new(:original_url).new("https://example.com/invoices/1")

    controller.define_singleton_method(:controller_name) { "invoices" }
    controller.define_singleton_method(:request) { request }
    controller.define_singleton_method(:render_options) { @render_options }
    controller.define_singleton_method(:send_options) { @send_options }
    controller.define_singleton_method(:sent_data) { @sent_data }
    controller.define_singleton_method(:render_to_string) do |options|
      @render_options = options
      "<html><body>Invoice</body></html>"
    end
    controller.define_singleton_method(:send_data) do |data, **options|
      @sent_data = data
      @send_options = options
    end

    controller
  end
end
