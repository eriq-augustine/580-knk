require './statement_parser.rb'
require './puzzle.rb'
require './puzzle_parser.rb'

puzzleFile = ARGV.shift()
puzzles = PuzzleParser.parseFile(puzzleFile)

count = 0
puzzles.each{|puzzle|
   count += puzzle.solve()
}

puts "\n#{count.to_f / puzzles.length() * 100}% Expressions Found"
