require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly two cases, not #{json['cases'].size}" if json['cases'].size != 2

def even_ones(x)
  x &= ~1
  x |= x.to_s(2).count(?1) & 1
end

verify(json['cases'][0]['cases'], property: 'transmitSequence') { |i, _|
  remain_sz = 0
  remain = 0
  (i['message'].map { |byte| Integer(byte, 16) }.each_with_object([]) { |x, out|
    out << even_ones(remain << (8 - remain_sz) | x >> remain_sz)
    remain_sz += 1
    remain = x & ((1 << remain_sz) - 1)
    if remain_sz == 7
      out << even_ones(remain << 1)
      remain = 0
      remain_sz = 0
    end
  } + (remain_sz > 0 ? [even_ones(remain << (8 - remain_sz))] : [])).map { |b| '0x%02x' % b }
}

def ensure_even_ones(x)
  raise "#{x} odd" if x.to_s(2).count(?1).odd?
  x & ~1
end

# byte 1: 1234567x (remain_sz = 0)
# byte 2: 8123456x
# byte 3: 7812345x
# byte 4: 6781234x
# byte 5: 5678123x
# byte 6: 4567812x
# byte 7: 3456781x
# byte 8: 2345678x (remain_sz = 7)
verify(json['cases'][1]['cases'], property: 'decodeMessage') { |i, _|
  remain_sz = 0
  (i['message'].map { |byte| ensure_even_ones(Integer(byte, 16)) }.each_with_object([]) { |x, out|
    out[-1] |= x >> (8 - remain_sz) if remain_sz > 0
    if remain_sz == 7
      remain_sz = 0
    else
      out << ((x << remain_sz) & 0xff)
      remain_sz += 1
    end
  })[..(i['message'].size % 8 == 0 ? -1 : -2)].map { |b| '0x%02x' % b }
}
