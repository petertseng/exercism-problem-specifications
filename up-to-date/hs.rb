require_relative 'up-to-date'

IGNORE_EXERCISES = {
  'beer-song' => 'refactoring exercise in Haskell, tests entire song only, https://github.com/exercism/haskell/pull/390',
  'food-chain' => 'refactoring exercise in Haskell, tests entire song only, https://github.com/exercism/haskell/pull/346',
  'house' => 'refactoring exercise in Haskell, tests entire song only, https://github.com/exercism/haskell/pull/348',

  'triangle' => 'currently divergent and staying with data, as of https://github.com/exercism/haskell/pull/484',
}

HASKELL = "#{__dir__}/../../haskell".freeze

UpToDate.report(HASKELL, IGNORE_EXERCISES) { |dir|
  version_lines = File.readlines(File.join(dir, 'package.yaml')).grep(/version:/)
  raise "Need one version line, got #{version_lines}" if version_lines.size != 1

  version_lines.first.split(': ').last.strip
}
