require 'json'

flat = ARGV.delete('--flat')
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

exercises_unlocked_by[nil].each { |x| puts "[free] #{x}" }

if flat
  puts '[core]'
  cores.each { |core| puts core }
  puts
  puts '[side]'
  prerequisite.sort_by(&:first).each { |k, v|
    puts "#{k} unlocked by #{v}"
  }
else
  cores.each { |core|
    puts core
    exercises_unlocked_by[core].each { |u| puts "    #{u}" }
  }
end
