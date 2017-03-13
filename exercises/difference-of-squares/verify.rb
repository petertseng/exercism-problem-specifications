require 'json'
require_relative '../../verify'

module Square refine Integer do
  def ssq
    (1..self).sum { |n| n * n }
  end

  def sqs
    (1..self).sum ** 2
  end
end end

using Square

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly three cases, not #{json['cases'].size}" if json['cases'].size != 3

verify(json['cases'][0]['cases'], property: 'squareOfSum') { |i, _|
  i['number'].sqs
}

verify(json['cases'][1]['cases'], property: 'sumOfSquares') { |i, _|
  i['number'].ssq
}

verify(json['cases'][2]['cases'], property: 'differenceOfSquares') { |i, _|
  i['number'].sqs - i['number'].ssq
}
