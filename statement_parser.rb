# Take a puzzle statement, and turn it into a logical expression.
# This parse take entire statement.
#  It will then figure out the context person, strip the context and
#  try different StatementHandlers.
# |fullStatement| should come in stripped and without ending punctuation.
class StatementParser
   @@tellingWords = "tells|says|claims"

   def self.parse(person1, person2, fullStatement)
      # TODO(eriq): If multiple Handlers respond, check if they agree?

      statement = resolveStatement(person1, person2, fullStatement)
      statement.expression = StatementHandler::handleStatement(
            statement.contextPerson, statement.otherPerson, statement.statement)
      return statement
   end

   # resolves both the context and statement.
   def self.resolveStatement(person1, person2, fullStatement)
      # TODO(eriq): Don't rely on first word.
      # First word is always the context person (so far...)
      match = nil
      if (!(match = fullStatement.match(/^(\w+)\s+/)))
         $stderr.puts "ERROR: Cannot find context. [#{fullStatement}]."
         return nil
      end

      context = match[1].upcase
      if (context != person1 && context != person2)
         $stderr.puts "ERROR: Context is not known person." +
                      " Full Statement: [#{fullStatement}]," +
                      " Known People: (#{person1}, #{person2})."
         return nil
      end
      otherPerson = (context == person1) ? person2 : person1

      # Most simple context case is a quote.
      match = nil
      if (match = fullStatement.match(/['"](.+)['"]$/))
         return Statement.new(context, otherPerson, match[1].strip)
      end

      # Look for a telling word
      # <someone> tells you
      # <someone> says that
      # The previous case should have caught many problematic cases.
      match = nil
      if (match = fullStatement.match(/(?:#{@@tellingWords})\s+(?:that|(?:you\s+(?:that)?))\s+(.+)$/))
         return Statement.new(context, otherPerson, match[1].strip)
      end

      # TODO(eriq): Better?
      $stderr.puts "WARNING: Falling back to three word statement parsing. [#{fullStatement}]"

      # Final tactic, strip the first three words.
      match = nil
      if (match = fullStatement.match(/(?:\w+\s+){3}(.+)$/))
         return Statement.new(context, otherPerson, match[1].strip)
      end

      $stderr.puts "ERROR: Unable to determine statement: [#{fullStatement}]"
      return nil
   end
end

# NOTE: The order of StatementHandlers matter, so be careful.

# TODO(eriq): Formal expressions
# Converts statements to Expression
class StatementHandler
   # TODO(eriq): Probabilites of a successful handle?
   def self.handleStatement(contextPerson, otherPerson, statement)
      @@handlers.each{|handler|
         expression = handler.handleStatement(contextPerson, otherPerson, statement)
         if (expression)
            return expression
         end
      }

      return nil
   end

   @@handlers = []

   def initialize()
      @@handlers << self
   end

   # Returns an expression on success, nil on failure
   def handleStatement(contextPerson, otherPerson, statement)
      $stderr.puts "Using the base handleStatement()"
      exit(1)
   end
end

# This is the most simple case and should be handled first.
# <other | 'I'> (am|is) a <knight|knave>
# This does not handle complex caluses like 'I am a knigh is he is a knave'
class DirectStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      match = nil
      if (match = statement.downcase.match(/^#{otherPerson.downcase}\s+is\s+a\s+(knight|knave)$/))
         return "#{otherPerson} = #{match[1].upcase}"
      elsif (match = statement.downcase.match(/^I\s+am\s+a\s+(knight|knave)$/))
         return "#{contextPerson} = #{match[1].upcase}"
      end

      return nil
   end

   @@instance = DirectStatementHandler.new()
end

# I and <other> are (both)? <knights|knaves>
# This does not handle complex caluses like 'I am a knigh is he is a knave'
class DoubleDirectStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      match = nil
      if ((match = statement.downcase.match(/^i\s+and\s+#{otherPerson.downcase}\s+are\s+(?:both\s+)?(knight|knave)s$/)) ||
          (match = statement.downcase.match(/^#{otherPerson.downcase}\s+and\s+i\s+are\s+(?:both\s+)?(knight|knave)s$/)))
         return "(#{contextPerson} = #{match[1].upcase}) && (#{otherPerson} = #{match[1].upcase})"
      end

      return nil
   end

   @@instance = DoubleDirectStatementHandler.new()
end

# Neither I nor <other> are <knights|knaves>
# The statement must have 'neither' and 'nor' and only one of 'knights' or 'knaves'
class NeitherNorStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      words = statement.downcase.split()
      if (words.include?('neither') && words.include?('nor'))
         if (words.include?('knights') && !words.include?('knaves'))
            return "(#{contextPerson} = KNAVE) && (#{otherPerson} = KNAVE)"
         elsif (!words.include?('knights') && words.include?('knaves'))
            return "(#{contextPerson} = KNIGHT) && (#{otherPerson} = KNIGHT)"
         end
      end

      return nil
   end

   @@instance = NeitherNorStatementHandler.new()
end

# I and <other> are both <knights|knaves> or both <knights|knaves>
# Be careful not to match complex patterns.
class DoubleBothStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      match = nil
      if ((match = statement.downcase.match(/both\s+knights\s+or\s+both\s+knaves$/)) ||
          (match = statement.downcase.match(/both\s+knaves\s+or\s+both\s+knights$/)))
         return "((#{contextPerson} = KNIGHT) && (#{otherPerson} = KNIGHT)) || ((#{contextPerson} = KNAVE) && (#{otherPerson} = KNAVE))"
      elsif ((match = statement.downcase.match(/both\s+not\s+knights\s+or\s+both\s+not\s+knaves$/)) ||
             (match = statement.downcase.match(/both\s+not\s+knaves\s+or\s+both\s+not\s+knights$/)))
         return "((#{contextPerson} = KNIGHT) && (#{otherPerson} = KNIGHT)) || ((#{contextPerson} = KNAVE) && (#{otherPerson} = KNAVE))"
      elsif ((match = statement.downcase.match(/not\s+both\s+knights\s+or\s+not\s+both\s+knaves$/)) ||
             (match = statement.downcase.match(/not\s+both\s+knaves\s+or\s+not\s+both\s+knights$/)))
         return "((#{contextPerson} = KNIGHT) && (#{otherPerson} = KNAVE)) || ((#{contextPerson} = KNAVE) && (#{otherPerson} = KNIGHT))"
      end

      return nil
   end

   @@instance = DoubleBothStatementHandler.new()
end

# Neither I nor <other> are <knights|knaves>



class Statement
   attr_reader(:contextPerson, :otherPerson, :statement, :expression)
   attr_accessor(:expression)

   def initialize(contextPerson, otherPerson, statement)
      @contextPerson = contextPerson
      @otherPerson = otherPerson
      @statement = statement
      @experssion = nil
   end

   def to_s()
      rtn = ''

      rtn += "Context Person: #{@contextPerson}.\n"
      rtn += "Other Person: #{@otherPerson}.\n"
      rtn += "Statement: #{@statement}.\n"
      rtn += "Expression: #{@expression}.\n"

      return rtn
   end
end
