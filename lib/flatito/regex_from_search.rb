# frozen_string_literal: true

module Flatito
  module RegexFromSearch
    def regex
      @regex ||= Regexp.new(search, case_sensitive ? nil : Regexp::IGNORECASE)
    end

    def value_regex
      @value_regex ||= Regexp.new(search_value, case_sensitive ? nil : Regexp::IGNORECASE)
    end
  end
end
