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

      res = []
      ['KNIGHT', 'KNAVE'].each{|person1Role|
         ['KNIGHT', 'KNAVE'].each{|person2Role|
            if (evalStatement(statement1.expression, statement2.expression, person1Role, person2Role))
               res << "#{@name1} = #{person1Role} && #{@name2} = #{person2Role}"
            end
         }
      }

      if (res.empty?)
         res << 'UNDECIDED'
      end

      return res
   end

   def evalStatement(expression1, expression2, person1Role, person2Role)
      #Negate someones expression if they are a KNAVE
      if (person1Role == 'KNAVE')
         expression1 = "!(#{expression1})"
      end
      if (person2Role == 'KNAVE')
         expression2 = "!(#{expression2})"
      end

      fullExpression = "(#{expression1}) && (#{expression2})"
      finalExpression = fullExpression.gsub(/#{@name1}/, person1Role).gsub(/#{@name2}/, person2Role)

      # Make the expression valid ruby
      rubyExpression = finalExpression.gsub('=', '==').gsub('KNIGHT', "'KNIGHT'").gsub('KNAVE', "'KNAVE'")

      #TEST
      #puts fullExpression
      #puts finalExpression
      #puts rubyExpression

      res = eval(rubyExpression)
      #puts res
      return res
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
