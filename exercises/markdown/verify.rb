require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def tag(tag, txt)
  "<#{tag}>#{txt}</#{tag}>"
end

verify(json['cases'], property: 'parse') { |i, _|
  i['markdown'].each_line.map { |l|
    l.gsub!(/__(.*)__/) { |m| tag('strong', $1) }
    l.gsub!(/_(.*)_/) { |m| tag('em', $1) }

    if l.start_with?(?#)
      non_hash = l.index(/[^#]/)
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
