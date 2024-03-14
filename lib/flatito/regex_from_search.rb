# frozen_string_literal: true

module Flatito
  module RegexFromSearch
    def regex
      @regex ||= Regexp.new(search)
    end
  end
end
