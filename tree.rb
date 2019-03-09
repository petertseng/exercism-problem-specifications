require 'json'

flat = ARGV.delete('--flat')
difficulty = ARGV.delete('-d')
r = JSON.parse(ARGV.empty? ? File.read('config.json') : ARGF.read)

cores = []
# String (unlocking exercise) => Array[String] (exercises unlocked by it)
exercises_unlocked_by = Hash.new { |h, k| h[k] = [] }
# String (unlocked exercise) => String (exercise that unlocks it)
prerequisite = {}

r['exercises'].each { |x|
  if x['deprecated']
    puts "[deprecated] #{x['slug']}"
  elsif x['core']
    cores << x['slug']
  else
    exercises_unlocked_by[x['unlocked_by']] << x['slug']
    prerequisite[x['slug']] = x['unlocked_by']
  end
}

fmt_exercise = r['exercises'].map { |e|
  [e['slug'].freeze, "#{e['slug']}#{" #{e['difficulty']}" if difficulty}"]
}.to_h.freeze

exercises_unlocked_by[nil].each { |x| puts "[free] #{fmt_exercise[x]}" }

if flat
  puts '[core]'
  cores.each { |core| puts fmt_exercise[core] }
  puts
  puts '[side]'
  prerequisite.sort_by(&:first).each { |k, v|
    puts "#{fmt_exercise[k]} unlocked by #{fmt_exercise[v]}"
  }
else
  cores.each { |core|
    puts fmt_exercise[core]
    exercises_unlocked_by[core].each { |u| puts "    #{fmt_exercise[u]}" }
  }
end
