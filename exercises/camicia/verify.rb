require 'json'
require_relative '../../verify'

def deck(strs)
  strs.map { |s|
    case s
    when ?A; :A
    when ?K; :K
    when ?Q; :Q
    when ?J; :J
    else Integer(s)
    end
  }
end

def idxs(deck, card)
  deck.each_with_index.filter_map { |c, i|
    i if c == card
  }.freeze
end

def deck_seen_key(deck)
  %i(J Q K A).map { |c| idxs(deck, c) }.freeze
end

CHANCES = {
  A: 4,
  K: 3,
  Q: 2,
  J: 1,
}.freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def game(deck1, deck2)
  decks = [deck1, deck2].freeze
  seen = {decks.map(&method(:deck_seen_key)).freeze => true}
  tricks = 0
  cards = 0
  pile = []
  turn_player = 0
  chances_left = nil
  until decks[turn_player].empty?
    play = decks[turn_player].shift
    cards += 1

    pile << play
    if CHANCES[play]
      chances_left = CHANCES[play]
      turn_player = 1 - turn_player
    elsif chances_left
      chances_left -= 1
      if chances_left == 0
        decks[1 - turn_player].concat(pile)
        break if decks[turn_player].empty?
        chances_left = nil
        pile.clear
        turn_player = 1 - turn_player
        tricks += 1
        seen_key = decks.map(&method(:deck_seen_key)).freeze
        return {
          'status' => 'loop',
          'cards' => cards,
          'tricks' => tricks,
        } if seen[seen_key]
        seen[seen_key] = true
      end
    else
      turn_player = 1 - turn_player
    end
  end

  {
    'status' => 'finished',
    'cards' => cards,
    'tricks' => tricks + 1,
  }
end

verify(json['cases'], property: 'simulateGame') { |i, _|
  game(deck(i['playerA']), deck(i['playerB']))
}
