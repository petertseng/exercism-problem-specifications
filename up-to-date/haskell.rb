require 'shellwords'
require_relative 'up-to-date'

DATE = '[0-9]{4}-[0-9][0-9]-[0-9][0-9]'.freeze

IGNORE_EXERCISES = {
  'beer-song' => 'refactoring exercise in Haskell, tests entire song only',
  'food-chain' => 'refactoring exercise in Haskell, tests entire song only',
  'house' => 'refactoring exercise in Haskell, tests entire song only',
}

IGNORE_COMMITS = {
  all: [
    # These move commits don't change test content.
    'cda8f98 Create new exercises structure',
  ],
  'nth-prime' => [
    # These move commits don't change test content.
    'ac8fb20 nth-prime: Move JSON data under new structure (#388)',
  ],
  'minesweeper' => [
    # Haskell generates the inputs from the outputs, so this commit is not meaningful.
    '0ea9e58 Provide inputs to minesweeper canonical data. (#452)',
    # Minesweeper: We put the numbers in the test data, we don't care.
    '5a134c3 minesweeper: remove number from input, add mines',
  ],
  'alphametics' => [
    # We already took these into account
    "9dab356 Add missing '=' in test. (#430)",
    'b760eb4 Add more easy cases. (#425)',
  ],
  'raindrops' => [
    # Raindrops: No descriptions for us (should we change it? I don't know)
    'e8fa348 Updated raindrop tests according to code review.',
    'f66b913 Add descriptions for the raindrops tests.',
  ],
  'all-your-base' => [
    # all-your-base: The name of the key is not important.
    '32aea4d Change all-your-base canonical data to use an expected key.',
  ],
  'word-count' => [
    # This doesn't affect test content.
    'f2ab262 word-count: replace underscore with space in description (#483)',
  ],
}

HASKELL = "#{__dir__}/../../xhaskell".freeze

UpToDate.report(HASKELL, IGNORE_EXERCISES, IGNORE_COMMITS) { |dir|
  haskell_test_file = File.join(dir, 'test', 'Tests.hs')
  date_lines = `grep -E '#{DATE}([^T]\|$)' #{haskell_test_file.shellescape}`.lines
  case date_lines.size
  when 1; Date.parse(date_lines.first.match(/#{DATE}/)[0])
  when 0; 'NO DATE LINE FOUND'
  else 'AMBIGUOUS DATE LINES'
  end
}
