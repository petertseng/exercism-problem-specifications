require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'reverse', implementations: [
  {
    name: 'grapheme',
    f: ->(i, _) {
      i['value'].grapheme_clusters.reverse.join
    }
  },
  {
    name: 'default',
    should_fail: true,
    f: ->(i, _) {
      i['value'].reverse
    }
  },
])
