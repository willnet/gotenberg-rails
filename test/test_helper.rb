# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "gotenberg/rails"

class FakeResponse
  attr_reader :code, :body

  def initialize(code:, body:)
    @code = code
    @body = body
  end
end

class FakeHTTPSuccess < Net::HTTPSuccess
  def initialize(body)
    super("1.1", "200", "OK")
    @body = body
  end

  attr_reader :body
end

class FakeClient
  attr_reader :calls

  def initialize(result = "%PDF")
    @result = result
    @calls = []
  end

  def render_pdf(**options)
    calls << options
    @result
  end
end
