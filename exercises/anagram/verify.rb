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

verify(json['cases'], property: 'findAnagrams') { |i, _|
  filter_by(i['subject'], i['candidates']) { |a, b| a.chars.sort == b.chars.sort }
}
