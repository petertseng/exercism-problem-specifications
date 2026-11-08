require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def adj(t, siblings: true)
  t.each_with_object(Hash.new { |h, k| h[k] = [] }) { |(u, vs), h|
    vs.each { |v|
      h[u] << v.freeze
      h[v] << u.freeze
    }
    vs.combination(2) { |v1, v2|
      h[v1] << v2.freeze
      h[v2] << v1.freeze
    } if siblings
  }.transform_values(&:freeze).tap { |h| h.default_proc = nil }.freeze
end

def steps(start, goal, adj)
  seen = {start => true}
  q = [start]
  gen = -1
  until q.empty?
    gen += 1
    return gen if q.include?(goal)
    q = q.flat_map(&adj).uniq - seen.keys
    q.each { |n| seen[n] = true }
  end
  nil
end

multi_verify(json['cases'], property: 'degreeOfSeparation', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      steps(i['personA'], i['personB'], adj(i['familyTree']))
    },
  },
  {
    name: 'no siblings',
    should_fail: true,
    f: ->(i, _) {
      steps(i['personA'], i['personB'], adj(i['familyTree'], siblings: false))
    },
  },
])
