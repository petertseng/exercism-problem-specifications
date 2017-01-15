require 'json'
require_relative '../../verify'

OPS = [
  ->(x) { x << 'wink' },
  ->(x) { x << 'double blink' },
  ->(x) { x << 'close your eyes' },
  ->(x) { x << 'jump' },
  :reverse!.to_proc,
].freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'commands') { |i, _|
  OPS.reduce([i['number'], []]) { |(n, ops), f|
    [n >> 1, n & 1 == 1 ? f[ops] : ops]
  }.last
}
