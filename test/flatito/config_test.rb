# frozen_string_literal: true

require "test_helper"

class Flatito::ConfigTest < Minitest::Test
  class DummyTTY < StringIO
    def tty?
      true
    end
  end

  class DummyNotTTY < StringIO
    def tty?
      false
    end
  end

  test "when stdout is tty set renderer as tty" do
    Flatito::Config.stdout = DummyTTY.new
    Flatito::Config.prepare_with_options({})

    assert_kind_of Flatito::Renderer::TTY, Flatito::Config.renderer
  end

  test "when stdout is not tty set renderer as plain" do
    Flatito::Config.stdout = DummyNotTTY.new
    Flatito::Config.prepare_with_options({})

    assert_kind_of Flatito::Renderer::Plain, Flatito::Config.renderer
  end
end
