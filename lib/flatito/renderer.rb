# frozen_string_literal: true

require "io/console"
require_relative "regex_from_search"

module Flatito
  class Renderer
    include RegexFromSearch

    def self.build(options)
      if tty?
        Renderer::TTY.new(options)
      else
        Renderer::Plain.new(options)
      end
    end

    def self.tty?
      $stdout.tty?
    end
  end

  class Base
    attr_reader :search, :no_color

    def initialize(options)
      @no_color = options[:no_color] || false
      @search = options[:search]
    end

    def prepare; end
    def print_file_progress(pathname); end
    def ending; end

    def print_pathname(pathname)
      puts colorize(pathname.to_s, :light_blue)
    end

    def print_items(items)
      line_number_padding = items.map(&:line).max.to_s.length

      items.each do |item|
        print_item(item, line_number_padding)
      end
      puts
      flush
    end

    def print_item(item, line_number_padding)
      line_number = colorize("#{item.line.to_s.rjust(line_number_padding)}: ", :light_yellow)
      value = if item.value.length.positive?
                colorize("=> #{item.value}", :gray)
              else
                ""
              end

      puts "#{line_number} #{matched_string(item.key)} #{value}\n"
    end

    private

    def flush
      stdout.flush
    end

    def regex
      @regex ||= Regexp.new(search)
    end

    def matched_string(string)
      return string if search.nil? || no_color?

      regex.match(string).to_a&.each do |match|
        string = string.gsub(/#{match}/, match.colorize(:light_red))
      end
      string
    end

    def no_color?
      ENV["TERM"] == "dumb" || ENV["NO_COLOR"] == "true" || no_color == true
    end

    def truncate(string, max = 50)
      string.length > max ? "#{string[0...max]}..." : string
    end

    def stdout
      $stdout
    end

    def colorize(string, color)
      no_color? ? string : string.colorize(color)
    end
  end

  class Renderer::Plain < Base
    def ending
      puts
    end
  end

  class Renderer::TTY < Base
    def initialize(options)
      super
      require "io/console"
    end

    def prepare
      listen_for_stdout_width_change
    end

    def print_file_progress(pathname)
      print "\r #{truncate(pathname.to_s, stdout_width - 4)}#{erase_line}"
    end

    def print_pathname(pathname)
      print erase_line
      super
    end

    def ending
      print erase_line
      puts
    end

    private

    def erase_line
      "\e[K\e[0G"
    end

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
