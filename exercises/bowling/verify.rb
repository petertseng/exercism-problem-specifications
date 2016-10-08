require 'json'
require_relative '../../verify'

class Game
  class BowlingError < StandardError; end

  FRAMES_PER_GAME = 10
  PINS_PER_FRAME = 10
  ROLLS_PER_FRAME = 2

  def initialize
    @current_frame = 0
    @rolls_this_frame = 0
    @frames = Array.new(FRAMES_PER_GAME, 0)
    @one_fill_frames = []
    @two_fill_frames = []
    @pins_up = PINS_PER_FRAME
  end

  def roll(pins)
    raise BowlingError, "Can't roll #{pins} on #{self}: Is complete" if complete?
    raise BowlingError, "Can't roll #{pins} on #{self}: Can't be negative" if pins < 0
    raise BowlingError, "Can't roll #{pins} on #{self}: There are only #{@pins_up} pins up" if pins > @pins_up

    @rolls_this_frame += 1
    @pins_up -= pins
    @pins_up = PINS_PER_FRAME if @pins_up == 0

    (@one_fill_frames + @two_fill_frames).each { |fill| @frames[fill] += pins }
    @one_fill_frames = @two_fill_frames
    @two_fill_frames = []

    if @current_frame < FRAMES_PER_GAME
      @frames[@current_frame] += pins
      next_frame! if this_frame_complete?
    end
  end

  def score
    raise BowlingError, "Can't score #{self}: Is incomplete" unless complete?
    @frames.sum
  end

  private

  def current_frame_score
    @frames[@current_frame]
  end

  def this_frame_complete?
    current_frame_score == PINS_PER_FRAME || @rolls_this_frame == ROLLS_PER_FRAME
  end

  def complete?
    @current_frame == FRAMES_PER_GAME && @one_fill_frames.empty? && @two_fill_frames.empty?
  end

  def next_frame!
    if @rolls_this_frame < ROLLS_PER_FRAME
      @two_fill_frames << @current_frame
    elsif current_frame_score == PINS_PER_FRAME
      @one_fill_frames << @current_frame
    end

    @current_frame += 1
    @pins_up = PINS_PER_FRAME
    @rolls_this_frame = 0
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'], %w(roll score))

cases['roll'].each { |c|
  error_expected = c['expected'].is_a?(Hash) && c['expected'].has_key?('error')
  # As of currently, every roll test expects an error.
  raise "case #{c} is a roll case that expects no error?" unless error_expected
}

verify(cases['roll'], property: 'roll') { |i, _|
  # Making sure previous rolls don't error.
  begin
    game = i['previousRolls'].each_with_object(Game.new) { |r, g| g.roll(r) }
  rescue => e
    e
  else
    game.roll(i['roll'])
  end
}

verify(cases['score'], property: 'score') { |i, _|
  # Making sure previous rolls don't error.
  begin
    game = i['previousRolls'].each_with_object(Game.new) { |r, g| g.roll(r) }
  rescue => e
    e
  else
    game.score
  end
}
