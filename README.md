# Gotenberg Rails

Render Rails HTML as PDFs with [Gotenberg](https://gotenberg.dev/).

## Installation

Add the gem to your Gemfile:

```ruby
gem "gotenberg-rails"
```

Run Gotenberg:

```sh
docker run --rm -p 3000:3000 gotenberg/gotenberg:8
```

## Usage

Render a PDF from a Rails controller:

```ruby
def show
  respond_to do |format|
    format.html
    format.pdf do
      render gotenberg_pdf: {}, disposition: :inline, filename: "invoice.pdf"
    end
  end
end
```

Customize the rendered template and Gotenberg options:

```ruby
def show
  render gotenberg_pdf: {
    print_background: true,
    paper_width: "8.27",
    paper_height: "11.7",
    margin_top: "0.4",
    margin_bottom: "0.4",
    margin_left: "0.4",
    margin_right: "0.4"
  },
  layout: "pdf",
  template: "invoices/show",
  disposition: :inline,
  filename: "invoice.pdf"
end
```

You can also render directly:

```ruby
Gotenberg::Rails.render_pdf(html: html)
Gotenberg::Rails.render_pdf(html: html, display_url: "https://example.com/invoice")
Gotenberg::Rails.render_pdf(url: "https://example.com/invoice")
```

Add a header or footer to every page by passing complete HTML documents:

```ruby
Gotenberg::Rails.render_pdf(
  html: html,
  header_html: "<html><body>Invoice</body></html>",
  footer_html: '<html><body>Page <span class="pageNumber"></span> of <span class="totalPages"></span></body></html>',
  pdf_options: {
    margin_top: "1in",
    margin_bottom: "1in"
  }
)
```

From a controller, Rails templates can be rendered separately for the header and footer:

```ruby
header_html = render_to_string(template: "invoices/header", layout: false)
footer_html = render_to_string(template: "invoices/footer", layout: false)

render gotenberg_pdf: {
  header_html: header_html,
  footer_html: footer_html,
  margin_top: "1in",
  margin_bottom: "1in"
}, template: "invoices/show", layout: "pdf"
```

Header and footer templates must each be complete HTML documents. They are rendered separately from the main page, so JavaScript and external stylesheets or images are unavailable. Embed images as Base64 data URLs and leave enough top and bottom margin to avoid clipping.

When rendering HTML, `display_url` is used to rewrite relative image, link, JavaScript, stylesheet, and CSS `url(...)` references to absolute URLs before sending the HTML to Gotenberg. Controller rendering uses `request.original_url` automatically.

Options are sent to Gotenberg as Chromium form fields. Ruby-style snake case keys are converted to Gotenberg camel case keys:

```ruby
Gotenberg::Rails.render_pdf(
  html: html,
  pdf_options: {
    print_background: true,
    emulated_media_type: "screen",
    wait_delay: "2s",
    fail_on_http_status_codes: [499, 599],
    metadata: { Title: "Invoice" }
  }
)
```

## Configuration

```ruby
Gotenberg::Rails.configure do |config|
  config.endpoint = ENV.fetch("GOTENBERG_ENDPOINT", "http://gotenberg:3000")
  config.open_timeout = 5
  config.request_timeout = 30
  config.headers = { "X-Request-Source" => "rails" }
  config.pdf_options = {
    print_background: true,
    prefer_css_page_size: true
  }
end
```

Gotenberg receives rendered HTML as an `index.html` upload. Use absolute URLs for stylesheets, images, and fonts that Gotenberg must fetch from your Rails app.

## License

The gem is available as open source under the terms of the MIT License.
