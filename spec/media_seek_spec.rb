#require_relative 'spec_helper'

require 'media_seek'

RSpec.describe MediaSeek do
  it 'has a version number' do
    expect(MediaSeek::VERSION).not_to be nil
  end

  # it 'does something useful' do
  #   expect(false).to eq(true)
  # end

  it 'tests fiber' do
    fib = Fiber.new do
      x, y = 0, 1

      loop do
        Fiber.yield y
        x, y = y, x + y
      end
    end

    2_000.times { puts fib.resume }
  end
end
