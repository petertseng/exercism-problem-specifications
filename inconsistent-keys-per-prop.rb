require 'json'

def cases(h)
  # top-level won't have a description, but all lower levels will.
  # therefore we have to unconditionally flat_map cases on the top level.
  # on lower levels we either flat_map cases or just return individuals.
  cases = ->(hh, path = [].freeze) {
    hh['cases']&.flat_map { |c|
      cases[c, (path + [hh['description'].freeze]).freeze]
    } || [hh.merge(path: path)]
  }
  h['cases'].flat_map(&cases)
end


Dir.glob("#{__dir__}/exercises/*/canonical-data.json") { |f|
  exercise = File.basename(File.dirname(f))
  props = cases(JSON.parse(File.read(f))).group_by { |c| c['property'] }
  props.each { |prop, cases|
    keys = cases.map { |c| c['input'].keys }.tally
    next if keys.size == 1

    puts "#{exercise} has inconsistent #{prop} keys:"
    puts
    keys.each { |ks, count|
      puts "* #{count} cases have #{ks}"
    }
    puts
  }
}
