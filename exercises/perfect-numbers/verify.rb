require 'json'
require_relative '../../verify'

module Perfect refine Integer do
  def classify
    raise 'nope' if self <= 0
    sum = (2..self**0.5).select { |f| self % f == 0 }.flat_map { |f| [f, self / f].uniq }.sum + (self == 1 ? 0 : 1)
    sum == self ? 'perfect' : sum < self ? 'deficient' : 'abundant'
  end
end end

using Perfect

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].flat_map { |c| c['cases'] }, property: 'classify') { |i, _|
  i['number'].classify
}
