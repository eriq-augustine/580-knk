require './statement_parser.rb'
require './puzzle.rb'
require './puzzle_parser.rb'

puzzleFile = ARGV.shift()
puzzles = PuzzleParser.parseFile(puzzleFile)

puzzles.each{|puzzle|
   puts puzzle.solve().join(' OR ')
}
