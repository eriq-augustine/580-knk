require './statement_parser.rb'
require './puzzle.rb'
require './puzzle_parser.rb'

puzzleFile = ARGV.shift()

if (!puzzleFile)
   puts "USAGE ruby puzzle_main.rb <puzzle file>"
   puts "Puzzle files can contain as many puzzles as you want."
   puts "A puzzle should be three lines."
   exit(0)
end

onePerLine = false
if (puzzleFile == '--fun')
   onePerLine = true
   puzzleFile = ARGV.shift()
end

puzzles = PuzzleParser.parseFile(puzzleFile, onePerLine)
puzzles.each{|puzzle|
   puts puzzle.solve().join(' OR ')
}
