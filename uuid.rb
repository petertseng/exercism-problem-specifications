require 'json'

uuid = Hash.new { |h, k| h[k] = [] }

valid_uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

(ARGV.empty? ? Dir.glob("#{__dir__}/configs/*.json") : ARGV).each { |f|
  track = File.basename(f, '.json')
  json = JSON.parse(File.read(f))
  (json['exercises'] || []).each { |e|
    unless valid_uuid.match?(e['uuid'])
      puts "invalid #{e['uuid']} #{track} #{e['slug']}"
      next
    end
    uuid[e['uuid'].strip.downcase] << [track, e['slug']]
  }
}


uuid.each { |k, v|
  puts "dup #{k} #{v}" if v.size > 1
}
