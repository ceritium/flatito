# frozen_string_literal: true

module Flatito
  module Utils
    def truncate(string, max = 50)
      string.length > max ? "#{string[0...max]}..." : string
    end
  end
end
