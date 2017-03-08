require 'json'
require_relative '../../verify'

class Clock
  def initialize(h, m)
    @h, @m = ((h * 60 + m) % (24 * 60)).divmod(60)
  end

  def self.from_json(j)
    new(*j.values_at('hour', 'minute'))
  end

  def +(m)
    self.class.new(@h, @m + m)
  end

  def to_s
    '%02d:%02d' % [@h, @m]
  end

  def to_i
    @h * 60 + @m
  end

  def ==(t)
    to_i == t.to_i
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly four cases, not #{json['cases'].size}" if json['cases'].size != 4

verify(json['cases'][0]['cases'], property: 'create') { |i, _|
  Clock.from_json(i).to_s
}

verify(json['cases'][1]['cases'], property: 'add') { |i, _|
  (Clock.from_json(i) + i['value']).to_s
}

verify(json['cases'][2]['cases'], property: 'subtract') { |i, _|
  (Clock.from_json(i) + -i['value']).to_s
}

verify(json['cases'][3]['cases'], property: 'equal') { |i, _|
  %w(clock1 clock2).map { |m| Clock.from_json(i[m]) }.reduce(:==)
}
