require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

ALL_LETTERS = 0x7fffffe
A = ?A.ord
Z = ?z.ord

verify(json['cases'], property: 'isPangram') { |i, _|
  seen = 0
  i['sentence'].each_codepoint.any? { |cp|
    A <= cp && cp <= Z && (seen = (seen | 1 << (cp & 31)) & ALL_LETTERS) == ALL_LETTERS
  }
}
