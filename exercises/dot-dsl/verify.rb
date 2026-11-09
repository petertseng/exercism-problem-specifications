require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def edgename(a, b)
  a, b = [a, b].sort
  "{#{a} #{b}}"
end

def parse_attr(s)
  if s.include?(?[)
    s, kv = s.split(?[)
    [s.strip.freeze, kv(kv)]
  elsif s.end_with?(?;)
    [s.delete_suffix(?;).strip.freeze, {}.freeze]
  else raise "bad #{s}"
  end
end

def kv(s)
  k, v = s.delete_prefix(?[).delete_suffix('];').split(?=)
  raise "no value #{s}" unless v
  raise "empty name #{s}" if k.empty?
  {k => %w(color style).include?(k) ? v : value(v)}
end

def value(v)
  return true if v == 'true'
  return false if v == 'false'
  v.start_with?(?") ? v.delete_prefix(?").delete_suffix(?") : Integer(v)
end

verify(json['cases'], property: 'parse') { |i, _|
  txt = i['text']
  raise 'bad open' unless txt.shift.strip == 'graph {'
  raise 'bad close' unless txt.pop.strip == ?}
  nodes = Hash.new { |h, k|
    # TODO: multiple letters???
    raise "not node #{k}" unless k.match?(/\A[a-z]\z/)
    h[k] = {}
  }
  edges = Hash.new { |h, k| h[k] = {} }
  attrs = {}

  txt.each { |l|
    l.strip!
    next if l.start_with?(?#) || l.start_with?('//')
    next attrs.merge!(kv(l)) if l.start_with?(?[)
    l, attr = parse_attr(l)
    if l.include?('--')
      raise "no dest #{l}" if l.strip.end_with?('--')
      l.split('--').map(&:strip).each_cons(2) { |a, b|
        puts "we have nodes: #{a} and #{b}"
        nodes[a]
        nodes[b]
        edges[edgename(a, b)].merge!(attr)
      }
    else
      # TODO: what if there's a duplicate?
      nodes[l].merge!(attr)
    end
  }

  {
    "nodes" => nodes,
    "edges" => edges,
    "attrs" => attrs,
  }
}
