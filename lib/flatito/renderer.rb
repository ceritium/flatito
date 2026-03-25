# frozen_string_literal: true

require "io/console"
require_relative "regex_from_search"
require_relative "utils"

module Flatito
  class Renderer
    def self.build(options)
      if Config.stdout.tty?
        Renderer::TTY.new(options)
      else
        Renderer::Plain.new(options)
      end
    end
  end

  class Base
    include Utils
    include RegexFromSearch

    attr_reader :search, :search_value, :no_color, :case_sensitive

    def initialize(options)
      @no_color = options[:no_color] || false
      @search = options[:search]
      @search_value = options[:search_value]
      @case_sensitive = options[:case_sensitive]
    end

    def prepare; end
    def print_file_progress(pathname); end
    def ending; end

    def print_pathname(pathname)
      stdout.puts colorize(pathname.to_s, :light_blue)
    end

    def print_items(items)
      line_number_padding = items.map(&:line).max.to_s.length

      items.each do |item|
        print_item(item, line_number_padding)
      end
      stdout.puts
      stdout.flush
    end

    def print_item(item, line_number_padding)
      line_number = colorize("#{item.line.to_s.rjust(line_number_padding)}: ", :yellow)
      value = if item.value.length.positive?
                display_value = truncate_value(item.value)
                colorize("=> ", :gray) + matched_value(display_value, :gray)
              else
                ""
              end

      stdout.puts "#{line_number} #{matched_string(item.key)} #{value}"
    end

    private

    def matched_string(string)
      return string if search.nil? || no_color?

      regex.match(string).to_a.each do |match|
        string = string.gsub(/#{match}/, match.colorize(:light_red))
      end
      string
    end

    def matched_value(string, default_color)
      return colorize(string, default_color) if search_value.nil? || no_color?

      value_regex.match(string).to_a.each do |match|
        string = string.gsub(/#{match}/, match.colorize(:light_red))
      end
      string
    end

    def truncate_value(string)
      match_position = search_value && value_regex.match(string)&.begin(0)
      truncate(string, match_position: match_position)
    end

    def value_regex
      @value_regex ||= Regexp.new(search_value, case_sensitive ? nil : Regexp::IGNORECASE)
    end

    def no_color?
      ENV["TERM"] == "dumb" || ENV["NO_COLOR"] == "true" || no_color == true
    end

    def stdout
      Config.stdout
    end

    def colorize(string, color)
      no_color? ? string : string.colorize(color)
    end
  end

  class Renderer::Plain < Base
    def ending
      stdout.puts
    end
  end

  class Renderer::TTY < Base
    CSI = "\e["
    CLEAR_LINE = "#{CSI}K\e[0G".freeze
    HIDE_CURSOR = "#{CSI}?25l".freeze
    SHOW_CURSOR = "#{CSI}?25h".freeze

    def initialize(options)
      super
      require "io/console"
    end

    def prepare
      listen_for_stdout_width_change
      hide_cursor
    end

    def print_file_progress(pathname)
      print truncate(pathname.to_s, stdout_width - 4)
      clear_line
    end

    def print_pathname(pathname)
      clear_line
      super
    end

    def ending
      clear_line
      show_cursor
      stdout.puts
    end

    def hide_cursor
      stdout.print HIDE_CURSOR
    end

    def show_cursor
      stdout.print SHOW_CURSOR
    end

    def clear_line
      stdout.print CLEAR_LINE
    end

    private

    def stdout_width
      @stdout_width ||= stdout.winsize[1]
    rescue StandardError
      80
    end

    def listen_for_stdout_width_change
      Signal.trap(:WINCH) do
        @stdout_width = stdout.winsize[1]
      end
    end
  end
end
