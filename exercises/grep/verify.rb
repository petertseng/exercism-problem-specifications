require 'json'
require 'open3'
require 'tmpdir'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = json['cases'].flat_map { |c| c['cases'] }

Dir.mktmpdir { |dir|
  Dir.chdir(dir) {
    filename = nil
    file_lines = []
    json['comments'].each { |line|
      if line.include?('.txt')
        filename = line.strip
        raise "Weird file #{filename}" unless /\A[-a-z]+\.txt\z/.match?(filename)
      elsif line.include?(?-) && line.strip.delete(?-).empty?
        File.open(filename, ?w) { |f| f.puts(file_lines.join("\n")) } unless file_lines.empty?
        file_lines.clear
      elsif line.include?(?|)
        file_lines << line.split(?|)[1].strip
      end
    }

    verify(cases, property: 'grep') { |i, _|
      Open3.capture2(*(['grep', i['pattern']] + i['flags'] + i['files'])).first.lines.map(&:chomp)
    }
  }
}
