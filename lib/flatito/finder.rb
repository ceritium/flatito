# frozen_string_literal: true

require "io/console"
module Flatito
  class Finder
    DEFAULT_EXTENSIONS = %w[json yml yaml].freeze

    attr_reader :paths, :search, :extensions

    def initialize(paths, options = {})
      @paths = paths
      @search = options[:search]
      @extensions = prepare_extensions(options[:extensions] || DEFAULT_EXTENSIONS)
      @no_color = options[:no_color] || false
      @skip_hidden = options[:skip_hidden] || true
    end

    def call
      listen_for_stdout_width_change

      paths.each do |path|
        TreeIterator.new(path, skip_hidden: @skip_hidden).each do |pathname|
          print "\r #{truncate(pathname.to_s, stdout_width - 4)}#{erase_line}" if tty?

          if extensions.include?(pathname.extname)
            items = FlattenYaml.new(pathname).flatten
            items = filter_by_search(items) if search

            next unless items.any?

            line_number_padding = items.map(&:line).max.to_s.length

            print erase_line if tty?
            puts colorize(pathname.to_s, :light_blue)

            # TODO: allow sorting by line number or key
            # items.sort_by(&:line).each do |item|
            items.each do |item|
              print_item(item, line_number_padding)
            end
            puts
          end

          $stdout.flush
        end
      end

      print erase_line if tty?
      puts
    end

    private

    def no_color?
      ENV["TERM"] == "dumb" || ENV["NO_COLOR"] == "true" || @no_color == true
    end

    def prepare_extensions(extensions)
      extensions.map do |ext|
        ext.start_with?(".") ? ext : ".#{ext}"
      end
    end

    def truncate(string, max = 50)
      string.length > max ? "#{string[0...max]}..." : string
    end

    def tty?
      $stdout.tty?
    end

    def stdout_width
      @stdout_width ||= $stdout.winsize[1]
    rescue StandardError
      80
    end

    def listen_for_stdout_width_change
      Signal.trap(:WINCH) do
        @stdout_width = $stdout.winsize[1]
      end
    end

    def erase_line
      "\e[K\e[0G"
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

    def filter_by_search(items)
      items.select do |item|
        regex.match?(item.key)
      end
    end

    def colorize(string, color)
      no_color? ? string : string.colorize(color)
    end

    def matched_string(string)
      return string if search.nil? || no_color?

      regex.match(string).to_a&.each do |match|
        string = string.gsub(/#{match}/, match.colorize(:light_red))
      end
      string
    end

    def regex
      @regex ||= Regexp.new(search)
    end
  end
end
