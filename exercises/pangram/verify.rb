require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

ALL_LETTERS = 0x7fffffe
A = ?A.ord
Z = ?z.ord

multi_verify(json['cases'], property: 'isPangram', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      seen = 0
      i['sentence'].each_codepoint.any? { |cp|
        A <= cp && cp <= Z && (seen = (seen | 1 << (cp & 31)) & ALL_LETTERS) == ALL_LETTERS
      }
    },
  },
  {
    name: 'by hash',
    f: ->(i, _) {
      chars = i['sentence'].upcase.each_char.to_h { |k| [k, nil] }
      (?A..?Z).all? { |l| chars.has_key?(l) }
    },
  },
  {
    name: 'just uniques',
    should_fail: true,
    f: ->(i, _) {
      i['sentence'].chars.uniq.size == 26
    },
  },
  # https://github.com/exercism/problem-specifications/pull/852
  {
    name: 'case-insensitive',
    should_fail: true,
    f: ->(i, _) {
      i['sentence'].chars.uniq.count { |c| (?a..?z).cover?(c) || (?A..?Z).cover?(c) } == 26
    },
  },
  # https://github.com/exercism/problem-specifications/pull/228
  {
    name: 'word characters',
    should_fail: true,
    f: ->(i, _) {
      i['sentence'].gsub(/[^\w]/, '').chars.uniq.size == 26
    },
  },
])
