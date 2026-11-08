require 'json'
require_relative '../../verify'

def fmt_time(t)
  min, sec = t.divmod(60)
  hour, min = min.divmod(60)
  '%02d:%02d:%02d' % [hour, min, sec]
end

def parse_time(ts)
  hour, min, sec = ts.split(?:)
  Integer(hour, 10) * 3600 + Integer(min, 10) * 60 + Integer(sec, 10)
end

class Stopwatch
  class BadState < Exception; end

  attr_reader :state

  def initialize
    @state = :ready
    @current_lap = 0
    @past_laps = []
    @total = 0
  end

  def current_lap
    fmt_time(@current_lap)
  end

  def total
    fmt_time(@total)
  end

  def past_laps
    @past_laps.map(&method(:fmt_time))
  end

  def start!
    case @state
    when :ready, :stopped
      @state = :running
    else raise BadState, "start from #@state"
    end
  end

  def stop!
    case @state
    when :running
      @state = :stopped
    else raise BadState, "stop from #@state"
    end
  end

  def lap!
    case @state
    when :running
      @past_laps << @current_lap
      @current_lap = 0
    else raise BadState, "lap from #@state"
    end
  end

  def reset!
    case @state
    when :stopped
      @past_laps = []
      # surely reset should reset the total?
      #@total = 0
      @current_lap = 0
      @state = :ready
    else raise BadState, "lap from #@state"
    end
  end

  def advance_time(t)
    if @state == :running
      @total += t
      @current_lap += t
    end
  end
end

def run_ops(ops)
  watch = nil

  ops.each_with_index { |op, j|
    expect = ->got { raise TestFailure, "#{op['command']} #{j} expected #{op['expected']} but got #{got}" if got != op['expected'] }
    maybe_expect_error = -> {
      if op.dig('expected', 'error')
        begin
          watch.public_send(op['command'] + ?!)
        rescue Stopwatch::BadState
        else raise TestFailure, "#{op} #{j} didn't error"
        end
      else
        watch.public_send(op['command'] + ?!)
      end
    }

    case op['command']
    when 'new'; watch = Stopwatch.new
    when 'state'; expect[watch.state.to_s]
    when 'currentLap'; expect[watch.current_lap]
    when 'total'; expect[watch.total]
    when 'previousLaps'; expect[watch.past_laps]
    when 'start', 'stop', 'lap', 'reset'; maybe_expect_error[]
    when 'advanceTime'; watch.advance_time(parse_time(op['by']))
    else raise "unknown op #{op}"
    end
  }
end

cases = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))['cases']

# Not the best fit for verify, since we just dispatch on operation and raise, accepting if we get to the end.
# However, this will change with the schema anyway, so we don't care.
verify(cases, accept: ->(_, _) { true }, property: 'time') { |i, _|
  run_ops(i['commands'])
}
