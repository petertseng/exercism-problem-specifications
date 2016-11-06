require_relative 'up-to-date'

TRACK_IGNORE_COMMITS = [
  '04b665e Move exercises into a directory',
].map { |s| [s, 0] }.to_h

IGNORE_EXERCISES = {
  'leap' => 'too lazy to deal w/ just description changes and reordering, the logic is all the same',
}

IGNORE_COMMITS = {
  all: [
    # These move commits don't change test content.
    'cda8f98 Create new exercises structure',
  ],
  'dominoes' => [
    # Rust complies to dominoes since its JSON was based on Rust.
    '66be399 dominoes: Add JSON test data',
  ],
  'all-your-base' => [
    # We don't care about the name.
    '32aea4d Change all-your-base canonical data to use an expected key.',
  ],
  'bowling' => [
    # We comply - Rust 7ccd8e4f6c6529f6ba3d9d34efd62b550e24583b
    '8396351 bowling: Add tests for more than 10 after last frame',
  ],
  'rna-transcription' => [
    # Rust has never had rna->dna cases.
    '0527321 rna-transcription: remove rna->dna cases from canonical data',
  ],
  'grains' => [
    # Typo is in test descriptions and doesn't affect Rust
    '79d01f2 Fix grains canonical data typo (#426)',
  ],
  'difference-of-squares' => [
    # We're actually missing the 10 cases.
    'a88568c difference-of-squares: adding test JSON',
    # Trailing whitespace, don't care
    '349024b Delete trailing whitespace',
  ],
  'robot-simulator' => [
    # We don't have this typo.
    '7b63bcd robot-simulator: fix typo s/directon/direction/',
  ],
  'bob' => [
    # Technically out of compliance, but I don't care.
    # Bob kinda, we don't have the same cases, but we don't have the non-ASCII chars.
    # So we're close enough to compliance.
    '45ff2e0 Remove non-Latin alphabetic characters, and unicode, from Bob. Also remove the file comment which looks to be not relevant any more.',
  ],
}

RUST = "#{__dir__}/../../xrust".freeze

UpToDate.report(RUST, IGNORE_EXERCISES, IGNORE_COMMITS) { |dir|
  # --follow won't work if Git is doing the globbing,
  # so do the glob in Ruby.
  test_file = Dir.glob(File.join(dir, 'tests', '*.rs')).tap { |a|
    raise "Need only 1 test file for #{dir}, have #{a}" unless a.size == 1
  }.first
  commits = Dir.chdir(RUST) {
    UpToDate.git_log(test_file, n: TRACK_IGNORE_COMMITS.size + 1)
  }.drop_while { |c|
    c_without_date = c['yyyy-mm-dd '.size..-1]
    TRACK_IGNORE_COMMITS.include?(c_without_date) && TRACK_IGNORE_COMMITS[c_without_date] += 1
  }
  Date.parse(commits.first.split.first)
}

puts 'Rust ignored commits:'
TRACK_IGNORE_COMMITS.each { |c, n| puts '%2d: %s' % [n, c] }
