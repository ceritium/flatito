# frozen_string_literal: true

require "psych"

module Flatito
  # Most of this magic comes from the following gist with a few modifications:
  # https://gist.github.com/johncarney/7332f7b2075b86ea52177a4a82453806
  module YAMLWithLineNumber
    ValueWithLineNumbers = Struct.new(:value, :line)

    class Whatever
      attr_reader :klassname

      def initialize(klassname)
        @klassname = klassname
      end

      def to_s
        "[object: #{klassname}]"
      end

      def method_missing(*)
        self
      end

      def respond_to_missing?(*)
        false
      end
    end

    class ClassLoader < Psych::ClassLoader
      def find(klassname)
        @cache[klassname] ||= resolve(klassname)
      rescue ArgumentError
        Whatever.new(klassname)
      end
    end

    class NodesScalar < Psych::Nodes::Scalar
      attr_reader :line_number

      def initialize(*args, line_number)
        super(*args)
        @line_number = line_number
      end
    end

    class TreeBuilder < Psych::TreeBuilder
      attr_accessor :parser

      def scalar(*args)
        node = NodesScalar.new(*args, parser.mark.line)
        @last.children << node
        node
      end
    end

    class VisitorsToRuby < Psych::Visitors::ToRuby
      def self.create(symbolize_names: false, freeze: false, strict_integer: false)
        class_loader = ClassLoader.new
        scanner      = Psych::ScalarScanner.new(class_loader, strict_integer: strict_integer)
        new(scanner, class_loader, symbolize_names: symbolize_names, freeze: freeze)
      end

      def visit_Flatito_YAMLWithLineNumber_NodesScalar(node) # rubocop:disable Naming/MethodName
        visit_Psych_Nodes_Scalar(node)
      end

      private

      def revive_hash(hash, node, _klass = nil)
        node.children.each_slice(2) do |k, v|
          key = accept(k)
          val = accept(v)

          if key == "<<" && k.tag != "tag:yaml.org,2002:str"
            case v
            when Psych::Nodes::Alias, Psych::Nodes::Mapping
              begin
                hash.merge! val
              rescue TypeError
                hash[key] = val
              end
            when Psych::Nodes::Sequence
              begin
                h = {}
                val.reverse_each do |value|
                  h.merge! value
                end
                hash.merge! h
              rescue TypeError
                hash[key] = val
              end
            else
              hash[key] = val
            end
          else
            if k.is_a? NodesScalar
              val = ValueWithLineNumbers.new(val, k.line_number + 1)
            end

            hash[key] = val
          end
        end

        hash
      end
    end
  end
end
