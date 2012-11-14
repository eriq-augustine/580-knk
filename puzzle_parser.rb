class PuzzleParser
   def self.parseFile(filename)
      file = File.open(filename, 'r')
      file.each{|line|
         puzzle = parsePuzzle(line)
      }
   end

   def self.parsePuzzle(text)
      originalText = text.strip

      #TEST
      puts originalText

      # To make good splits, replace ".'" with "'."
      # Proper puzzles contain exactly three sentences.
      sentences = originalText.gsub(/\.(['"])/, '\1.').split('.')

      if (sentences.length() != 3)
         puts "Failed to parse puzzle, not three sentences: [#{originalText}]."
         return nil
      end

      nameStatement = sentences[0].strip
      puzzleStatement = [sentences[1].strip, sentences[2].strip]

      match = nil
      if (!(match = nameStatement.match(/:\s*(\w+)\s+and\s+(\w+)/i)))
         puts "Failed to parse puzzle, cannot get names: [#{nameStatement}]."
         return nil
      end
      name1 = match[1].upcase
      name2 = match[2].upcase

      

      puts ""
   end
end

PuzzleParser.parseFile('puzzles.txt')
