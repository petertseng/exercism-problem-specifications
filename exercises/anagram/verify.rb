require 'json'
require_relative '../../verify'

def filter_by(subject, candidates, exclude_self: true, downcase: true)
  candidates.select { |candidate|
    subj, cand = [subject, candidate].map { |x| x.public_send(downcase ? :downcase : :itself) }
    next false if exclude_self && subj == cand
    yield(subj, cand)
  }
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'findAnagrams', implementations: [
  [true, true],
  [false, true],
  [true, false],
  # false false is not so useful, assuming either false causes fail
].map { |exclude_self, downcase|
  {
    name: "same letters case #{'in' if downcase}sensitive #{exclude_self ? 'ex' : 'in'}cluding self",
    should_fail: !exclude_self || !downcase,
    f: ->(i, _) {
      filter_by(i['subject'], i['candidates'], exclude_self: exclude_self, downcase: downcase) { |a, b| a.chars.sort == b.chars.sort }
    }
  }
} + {
  true: ->(_, _) { true },
  false: ->(_, _) { false },
  same_sum: ->(a, b) { a.chars.sum(&:ord) == b.chars.sum(&:ord) },
  left_has_right: ->(a, b) { a.chars.select { |c| (?a..?z).cover?(c.downcase) }.all? { |c| b.include?(c) } },
  right_has_left: ->(a, b) { b.chars.select { |c| (?a..?z).cover?(c.downcase) }.all? { |c| a.include?(c) } },
  same_letters: ->(a, b) {
    a_letters, b_letters = [a, b].map { |w| w.chars.select { |c| (?a..?z).cover?(c.downcase) }.uniq.sort }
    a_letters == b_letters
  },
}.map { |name, impl| {
  name: name,
  should_fail: true,
  f: ->(i, _) {
    filter_by(i['subject'], i['candidates'], &impl)
  }
}} + [
  {
    # https://github.com/exercism/problem-specifications/pull/1552
    name: 'immediately report none if same word found',
    should_fail: true,
    f: ->(i, _) {
      return [] if i['candidates'].any? { |x| x.downcase == i['subject'].downcase }
      filter_by(i['subject'], i['candidates']) { |a, b| a.chars.sort == b.chars.sort }
    }
  },
])
