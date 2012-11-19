require './puzzle.rb'

class PuzzleParser
   def self.parseFile(filename, onePerLine)
      puzzles = []

      count = 0
      file = File.open(filename, 'r')

      file.each{|line|
         count += 1

         if (!onePerLine)
            if (count == 1)
               next
            elsif (count == 3)
               count = 0
               next
            end
         end

         puzzle = nil
         if (puzzle = parsePuzzle(line))
            puzzles << puzzle
            #puts puzzle
            #puts ""
         else
            $stderr.puts "Failed to parse puzzle"
         end
      }

      return puzzles
   end

   def self.parsePuzzle(text)
      originalText = text.strip

      # To make good splits, replace ".'" with "'."
      # Proper puzzles contain exactly three sentences.
      sentences = originalText.gsub(/\.(['"])/, '\1.').split('.')

      if (sentences.length() != 3)
         $stderr.puts "Failed to parse puzzle, not three sentences: [#{originalText}]."
         return nil
      end

      nameStatement = sentences[0].strip.gsub(/\s+/, ' ')
      puzzleStatements = [sentences[1].strip.gsub(/\s+/, ' '), sentences[2].strip.gsub(/\s+/, ' ')]

      match = nil
      if (!(match = nameStatement.match(/:\s*(\w+)\s+and\s+(\w+)/i)))
         $stderr.puts "Failed to parse puzzle, cannot get names: [#{nameStatement}]."
         return nil
      end
      name1 = match[1].upcase
      name2 = match[2].upcase

      return Puzzle.new(name1, name2, originalText, nameStatement, puzzleStatements)
   end
end

#PuzzleParser.parseFile('puzzles.txt')
