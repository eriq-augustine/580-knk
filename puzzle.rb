class Puzzle
   def initialize(name1, name2, originalText, nameStatement, puzzleStatements)
      @name1 = name1
      @name2 = name2

      @originalText = originalText
      @nameStatement = nameStatement
      @puzzleStatements = puzzleStatements
   end

   # TODO(eriq)
   def solve()
     statement1 = StatementParser.parse(@name1, @name2, @puzzleStatements[0])
     statement2 = StatementParser.parse(@name1, @name2, @puzzleStatements[1])

     puts @puzzleStatements[0]
     puts statement1
     puts ""
     puts @puzzleStatements[1]
     puts statement2
     puts ""

     # TEST
     return (statement1.expression ? 1 : 0) + (statement2.expression ? 1 : 0)
   end

   def to_s()
      rtn = ''

      rtn += "Original: #{@originalText}\n"
      rtn += "Name Statement: #{@nameStatement}\n"
      rtn += "Puzzle Statement 1: #{@puzzleStatements[0]}\n"
      rtn += "Puzzle Statement 2: #{@puzzleStatements[1]}\n"
      rtn += "Name 1: #{@name1}\n"
      rtn += "Name 2: #{@name2}\n"

      return rtn
   end
end
