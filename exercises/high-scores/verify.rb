require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'].flat_map { |c| c.has_key?('cases') ? c['cases'] : [c] }, %w(scores latest personalBest personalTopThree latestAfterTopThree scoresAfterTopThree))

verify(cases['scores'], property: 'scores') { |i, _|
  i['scores']
}

verify(cases['scoresAfterTopThree'], property: 'scoresAfterTopThree') { |i, _|
  i['scores']
}

verify(cases['latest'], property: 'latest') { |i, _|
  i['scores'][-1]
}

verify(cases['latestAfterTopThree'], property: 'latestAfterTopThree') { |i, _|
  i['scores'][-1]
}

verify(cases['personalBest'], property: 'personalBest') { |i, _|
  i['scores'].max
}

verify(cases['personalTopThree'], property: 'personalTopThree') { |i, _|
  i['scores'].max(3)
}
