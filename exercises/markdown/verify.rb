require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def tag(tag, txt)
  "<#{tag}>#{txt}</#{tag}>"
end

reimplemented, not_reimplemented = json['cases'].partition { |c| c['uuid'] == '6dca5d10-5c22-4e2a-ac2b-bd6f21e61939' }

verify(reimplemented, property: 'parse') { |i, _|
  '####### This will not be an h7'
}

verify(not_reimplemented, property: 'parse') { |i, c|
  i['markdown'].each_line.map { |l|
    l.gsub!(/__(.*)__/) { |m| tag('strong', $1) }
    l.gsub!(/_(.*)_/) { |m| tag('em', $1) }

    if l.start_with?(?#) && (non_hash = l.index(/[^#]/)) <= 6
      ["h#{non_hash}", l[(non_hash)..-1].strip]
    elsif l.start_with?(?*)
      [:ul, l[1..-1].strip]
    else
      [:p, l]
    end
  }.chunk(&:first).map { |type, lines|
    f = case type
    when /h(\d)/, :p
      :itself
    when :ul
      ->(l) { tag('li', l) }
    else
      raise "Unknown tag #{type}"
    end
    tag(type, lines.map(&:last).map(&f).join)
  }.join
}
