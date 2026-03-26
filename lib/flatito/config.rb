# frozen_string_literal: true

module Flatito
  module Config
    @stdout = $stdout

    class << self
      attr_accessor :renderer, :stdout

      def prepare_with_options(options)
        self.renderer = Renderer.build(options)
      end
    end
  end
end
