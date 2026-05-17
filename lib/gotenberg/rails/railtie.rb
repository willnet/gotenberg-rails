# frozen_string_literal: true

require "action_controller/railtie"

module Gotenberg
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "gotenberg_rails.renderer" do
        ActiveSupport.on_load(:action_controller) do
          Gotenberg::Rails::Renderer.register
        end
      end
    end
  end
end
