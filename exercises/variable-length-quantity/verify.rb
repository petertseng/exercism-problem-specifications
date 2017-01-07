require 'json'
require_relative '../../verify'

SIZE = 7
MORE = 1 << SIZE
MAX = 2 ** 32 - 1

def encode(xs)
  xs.flat_map { |x|
    bytes = []
    while x >= MORE
      x, byte = x.divmod(MORE)
      bytes << byte
    end
    bytes << x
    bytes.reverse!
    bytes[0..-2].map { |v| v | MORE } << bytes[-1]
  }
end

def decode(bytes)
  bytes.reduce([[], 0]) { |(xs, val), byte|
    if val == 0 && byte == MORE
      raise 'nah'
    elsif byte & MORE != 0
      [xs, val << SIZE | byte & ~MORE]
    else
      [xs << (val << SIZE | byte).tap { |x| raise "#{x} too big" if x > MAX }, 0]
    end
  }.tap { |_, z| raise "#{z} leftover" if z != 0 }.first
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly two cases, not #{json['cases'].size}" if json['cases'].size != 2

verify(json['cases'][0]['cases'], property: 'encode') { |i, _|
  encode(i['integers'])
}

verify(json['cases'][1]['cases'], property: 'decode') { |i, _|
  decode(i['integers'])
}
