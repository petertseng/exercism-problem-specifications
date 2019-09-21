require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'truncate', implementations: [
  {
    name: 'string index',
    f: ->(i, _) { i['phrase'][0...5] },
  },
  {
    name: 'chars',
    f: ->(i, _) { i['phrase'].chars.take(5).join },
  },
  {
    name: 'bytes',
    should_fail: true,
    f: ->(i, _) { i['phrase'].bytes.take(5).pack('C*').force_encoding('utf-8') },
  },
])
