require 'open3'

yes = ARGV.delete('--yes')
repo = case ARGV[0]
when 'hs'; 'haskell'.freeze
when 'rs'; 'rust'.freeze
else raise "bad repo #{ARGV[0]}"
end

track = "#{__dir__}/../#{repo}".freeze
practices = Dir.glob("#{track}/exercises/practice/*/")

practices.each { |practice|
  exercise = File.basename(practice)
  f = "#{__dir__}/exercises/#{exercise}/description.md"
  next unless File.exist?(f)
  new_desc = File.read(f)
  new_desc['# Description'] = '# Instructions' if new_desc.start_with?('# Description')

  inst = "#{practice}/.docs/instructions.md".freeze
  old_desc = File.read(inst)
  next if old_desc == new_desc

  if yes
    File.write(inst, new_desc)
  else
    outerr, _stat = Open3.capture2e('colordiff', '-u', inst, '-', stdin_data: new_desc)
    puts outerr
  end
}
