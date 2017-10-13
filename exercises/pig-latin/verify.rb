require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

vowel = /[aeiou]|^xr|^yt/

not_reimplemented = json['cases'].flat_map { |c| c['cases'] }.reject { |c| c['uuid'] == '44616581-5ce3-4a81-82d0-40c7ab13d2d0' }

verify(not_reimplemented, property: 'translate') { |i, _|
  i['phrase'].split.map { |word|
    cut = case first_vowel = word =~ vowel
    when nil; word.index(?y)
    when 0; 0
    else
      first_vowel + (word[first_vowel - 1, 2] == 'qu' ? 1 : 0)
    end
    word[cut..-1] + word[0...cut] + 'ay'
  }.join(' ')
}
