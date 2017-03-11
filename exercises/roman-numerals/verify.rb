require 'json'
require_relative '../../verify'

module Roman
  ONES = {
    1000 => ?M,
    100  => ?C,
    10   => ?X,
    1    => ?I,
  }.each_value(&:freeze).freeze
  FIVES = {
    500 => ?D,
    50  => ?L,
    5   => ?V,
  }.each_value(&:freeze).freeze

  def self.repeat(val, sym, reps)
    case reps
    when 9;    sym + ONES[10 * val]
    when 5..8; FIVES[5 * val] + sym * (reps - 5)
    when 4;    sym + FIVES[5 * val]
    else       sym * reps
    end
  end

  refine Integer do
    def to_roman
      Roman::ONES.reduce([self, '']) { |(n, str), (val, sym)|
        reps, remain = n.divmod(val)
        [remain, str + Roman.repeat(val, sym, reps)]
      }.last
    end
  end
end

using Roman

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'roman') { |i, _|
  i['number'].to_roman
}
