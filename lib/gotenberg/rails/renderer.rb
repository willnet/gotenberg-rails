# frozen_string_literal: true

module Gotenberg
  module Rails
    module Renderer
      def self.register
        ActionController::Renderers.add :gotenberg_pdf do |options, render_options|
          pdf_options = options || {}
          filename = render_options[:filename] || pdf_options.delete(:filename) || "#{controller_name}.pdf"
          disposition = render_options[:disposition] || pdf_options.delete(:disposition) || "attachment"
          display_url = render_options[:display_url] || pdf_options.delete(:display_url) || request.original_url

          html = render_to_string(render_options.except(:display_url, :filename, :disposition).merge(formats: [:html]))
          pdf = Gotenberg::Rails.render_pdf(html:, display_url:, pdf_options:, filename:)

          send_data pdf,
                    filename: filename,
                    type: "application/pdf",
                    disposition: disposition
        end
      end
    end
  end
end
