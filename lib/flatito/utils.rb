# frozen_string_literal: true

module Flatito
  module Utils
    def truncate(string, max: 50, match_position: nil)
      return string if string.length <= max

      if match_position && match_position > max
        start = [match_position - (max / 2), 0].max
        ending = start + max
        result = string[start...ending]
        result = "...#{result}" if start.positive?
        result = "#{result}..." if ending < string.length
        result
      else
        "#{string[0...max]}..."
      end
    end
  end
end
