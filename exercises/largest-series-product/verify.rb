require 'json'
require_relative '../../verify'

class Series
  def initialize(string)
    raise ArgumentError, 'String has invalid digits' unless /^[0-9]*$/.match?(string)
    @size = string.size
    @segments = string.split(?0).map { |s| s.each_char.map(&:to_i) }
  end

  def largest_product(window_size)
    raise ArgumentError, "window size #{window_size} > numbers size #{@size}" if window_size > @size
    raise ArgumentError, "window size #{window_size} negative" if window_size < 0
    return 1 if window_size == 0

    @segments.select { |seg| seg.size >= window_size }.map { |seg|
      seg.drop(window_size - 1).zip(seg).reduce([0, seg.take(window_size - 1).reduce(1, :*)]) { |(max, prod), (add, drop)|
        new_prod = prod * add
        [[max, new_prod].max, new_prod / drop]
      }.first
    }.max || 0
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'largestProduct') { |i, _|
  Series.new(i['digits']).largest_product(i['span'])
}
