require 'json'

r = JSON.parse(ARGV.empty? ? File.read('config.json') : ARGF.read)

r['exercises'].sort_by { |x| x['slug'] }.each { |x|
  (x['topics'] || []).each { |t|
    puts "#{x['slug']} topic #{t}"
  }
}
