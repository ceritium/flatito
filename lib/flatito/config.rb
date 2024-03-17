# frozen_string_literal: true

module Flatito
  module Config
    @stdout = $stdout
    @stderr = $stderr
    @stdin  = $stdin

    class << self
      attr_accessor :renderer, :stdout, :stder, :stdin

      def prepare_with_options(options)
        self.renderer = Renderer.build(options)
      end
    end
  end
end
