require 'json'
require_relative '../../verify'

cases = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))['cases']

raise "There should be exactly two cases, not #{cases.size}" if cases.size != 2

# All these verifies are intentionally garbage:

random_cases = by_property(cases[0]['cases'], %w(encode decode key))

verify(random_cases['encode'], property: 'encode') { |i, _|
  'cipher.key.substring(0, plaintext.length)'
}

verify(random_cases['decode'], property: 'decode') { |i, _|
  i['plaintext'] || 'aaaaaaaaaa'
}

verify(random_cases['key'], property: 'key') { |i, _|
  {'match' => '^[a-z]+$'}
}

# This is the real stuff.

module Cipher
  refine String do
    def letter_codes
      each_char.map { |x| x.ord - ?a.ord }
    end

    def encipher(key, direction:)
      letter_codes.zip(key.letter_codes.cycle).map { |a, b| (a.send(direction, b) % 26 + ?a.ord).chr }.join
    end
  end

  refine Array do
    def as_letters
      map { |x| (x % 26 + ?a.ord).chr }.join
    end
  end
end

cases = by_property(cases[1]['cases'], %w(encode decode))

using Cipher

verify(cases['encode'], property: 'encode') { |i, _|
  i['plaintext'].encipher(i['key'], direction: :+)
}

verify(cases['decode'], property: 'decode') { |i, _|
  (ct = i['ciphertext']) == 'cipher.encode' ? i['plaintext'] : ct.encipher(i['key'], direction: :-)
}
