# Only for use in regex
TELLING_WORDS = "(?:(?:tells?)|(?:says?)|(?:claims?))"

# Take a puzzle statement, and turn it into a logical expression.
# This parse take entire statement.
#  It will then figure out the context person, strip the context and
#  try different StatementHandlers.
# |fullStatement| should come in stripped, without ending punctuation, and with a single space as the only delimiting whitespace.
class StatementParser
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
      if (!(match = fullStatement.match(/^(\w+) /)))
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
      if (match = fullStatement.match(/(?:#{TELLING_WORDS}) (?:that|(?:you (?:that)?)) (.+)$/))
         return Statement.new(context, otherPerson, match[1].strip)
      end

      # TODO(eriq): Better?
      $stderr.puts "WARNING: Falling back to three word statement parsing. [#{fullStatement}]"

      # Final tactic, strip the first three words.
      match = nil
      if (match = fullStatement.match(/(?:\w+ ){3}(.+)$/))
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
      if (match = statement.downcase.match(/^#{otherPerson.downcase} is a (knight|knave)$/))
         return "#{otherPerson} = #{match[1].upcase}"
      elsif (match = statement.downcase.match(/^i am a (knight|knave)$/))
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
      if ((match = statement.downcase.match(/^i and #{otherPerson.downcase} are (?:both )?(knight|knave)s$/)) ||
          (match = statement.downcase.match(/^#{otherPerson.downcase} and i are (?:both )?(knight|knave)s$/)))
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
      if ((match = statement.downcase.match(/both knights or both knaves$/)) ||
          (match = statement.downcase.match(/both knaves or both knights$/)))
         return "((#{contextPerson} = KNIGHT) && (#{otherPerson} = KNIGHT)) || ((#{contextPerson} = KNAVE) && (#{otherPerson} = KNAVE))"
      elsif ((match = statement.downcase.match(/both not knights or both not knaves$/)) ||
             (match = statement.downcase.match(/both not knaves or both not knights$/)))
         return "((#{contextPerson} = KNIGHT) && (#{otherPerson} = KNIGHT)) || ((#{contextPerson} = KNAVE) && (#{otherPerson} = KNAVE))"
      elsif ((match = statement.downcase.match(/not both knights or not both knaves$/)) ||
             (match = statement.downcase.match(/not both knaves or not both knights$/)))
         return "((#{contextPerson} = KNIGHT) && (#{otherPerson} = KNAVE)) || ((#{contextPerson} = KNAVE) && (#{otherPerson} = KNIGHT))"
      end

      return nil
   end

   @@instance = DoubleBothStatementHandler.new()
end

# "Both I and <other> are (not the same)|different"
class DoubleDifferenceStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      match = nil
      if ((match = statement.downcase.match(/^(both )?i and #{otherPerson.downcase} are ((not the same)|(different))$/)) ||
          (match = statement.downcase.match(/^(both )?#{otherPerson.downcase} and i are ((not the same)|(different))$/)))
         return "((#{contextPerson} = KNIGHT) && (#{otherPerson} = KNAVE)) || ((#{contextPerson} = KNAVE) && (#{otherPerson} = KNIGHT))"
      end

      return nil
   end

   @@instance = DoubleDifferenceStatementHandler.new()
end

# "Both I and <other> are (the same)|identical"
class DoubleSameStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      match = nil
      if ((match = statement.downcase.match(/^(both )?i and #{otherPerson.downcase} are ((the same)|(identical))$/)) ||
          (match = statement.downcase.match(/^(both )?#{otherPerson.downcase} and i are ((the same)|(identical))$/)))
         return "((#{contextPerson} = KNIGHT) && (#{otherPerson} = KNIGHT)) || ((#{contextPerson} = KNAVE) && (#{otherPerson} = KNAVE))"
      end

      return nil
   end

   @@instance = DoubleSameStatementHandler.new()
end

# "Both I and <other> are (knights|knaves)"
class DoubleSameNamedStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      match = nil
      if ((match = statement.downcase.match(/^(?:both )?i and #{otherPerson.downcase} are (knight|knave)s$/)) ||
          (match = statement.downcase.match(/^(?:both )?#{otherPerson.downcase} and i are (knight|knave)s$/)))
         return "(#{contextPerson} = #{match[1].upcase}) && (#{otherPerson} = #{match[1].upcase})"
      end

      return nil
   end

   @@instance = DoubleSameNamedStatementHandler.new()
end

# "it's false that  ..."
# "it's not the case that ..."
# "only a knave would say that  ..." This one is a bit more tricky, but the effect is the same.
class ItsFalseThatStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      match = nil
      if (match = statement.downcase.match(/^(?:(?:it's false)|(?:it's not the case)|(?:only a knave would #{TELLING_WORDS})) that (.+)$/))
         negation = StatementHandler::handleStatement(contextPerson, otherPerson, match[1])

         if (negation)
            return "!(#{negation})"
         end
      end

      return nil
   end

   @@instance = ItsFalseThatStatementHandler.new()
end

# "Of I and Alice, exactly one ..."
class OfThisAndThatStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      match = nil
      if ((match = statement.downcase.match(/^of i and #{otherPerson.downcase}, (?:exactly )?one is a (knight|knave)$/)) ||
          (match = statement.downcase.match(/^of #{otherPerson.downcase} and i, (?:exactly )?one is a (knight|knave)$/)))
         return "((#{contextPerson} = KNIGHT) && (#{otherPerson} = KNAVE)) || ((#{contextPerson} = KNAVE) && (#{otherPerson} = KNIGHT))"
      end

      return nil
   end

   @@instance = OfThisAndThatStatementHandler.new()
end

# Note that The converse of this (I as the subject) adds no information and was removed by a GlobalReplacer.
# "<other> could say that <statement>"
# The statement is usully "I am a (knight|knave)", but there is no reason not to abstract is some.
# This statement means that either the substatement is true and other is a knight, or it is false and other is a knave
class CouldSayThatStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      match = nil
      if (match = statement.downcase.match(/^#{otherPerson.downcase} (?:could|would) #{TELLING_WORDS} (?:you )?that (.+)$/))
         substatement = StatementHandler::handleStatement(contextPerson, otherPerson, match[1])
         if (substatement)
            return "((#{otherPerson} = KNIGHT) && (#{substatement})) || ((#{otherPerson} = KNAVE) && !(#{substatement}))"
         end
      end

      return nil
   end

   @@instance = CouldSayThatStatementHandler.new()
end

# NOTE: This should be one of the LAST StatementHandlers (it is recursive)
# TODO(eriq): Potentiall run the new statements through another GlobalReplace
# Split statements on an "and" or "or".
# Try to handle each one individually and then combine them.
class ConjunctionSplitStatementHandler < StatementHandler
   def handleStatement(contextPerson, otherPerson, statement)
      match = nil
      if (match = statement.downcase.match(/^(?:(?:either|both) )?(.+) (or|and) (.+)$/))
         operator = match[2] == 'or' ? '||' : '&&'
         lhs = nil
         rhs = nil

         if ((lhs = StatementHandler::handleStatement(contextPerson, otherPerson, match[1])) &&
             (rhs = StatementHandler::handleStatement(contextPerson, otherPerson, match[3])))
            return "((#{lhs}) #{operator} (#{rhs}))"
         else
            return nil
         end
      end

      return nil
   end

   @@instance = ConjunctionSplitStatementHandler.new()
end


# These are responsible for making replacements that are safe to always make if they are available.
class GlobalReplacer
   @@replacers = []

   def initialize()
      @@replacers << self
   end

   def self.replace(statement)
      rtn = statement

      @@replacers.each{|replacer|
         rtn = replacer.replace(rtn)
      }

      return rtn
   end

   # Return the replaced string (the same string if no replacement)
   def replace(statement)
      $stderr.puts "ERROR: base global replace"
      exit(1)
   end
end

# Don't be fooled, this adds no info.
# "I would tell you that ..." -> "..."
class WouldTellYouThatReplacer < GlobalReplacer
   def replace(statement)
      return statement.gsub(/(I would #{TELLING_WORDS} you that )|(I could #{TELLING_WORDS} that )/i, '').strip
   end

   @@instance = WouldTellYouThatReplacer.new()
end

# TODO(eriq): More general. There is usually an or ofter this.
# "At least one of the following is true: that .A. or that .B." -> ".A. or .B."
class AtLeastOneReplacer < GlobalReplacer
   def replace(statement)
      if (match = statement.match(/^At least one of the following is true: that (.+) or that (.+)$/))
         return "#{match[1]} or #{match[2]}"
      end

      return statement
   end

   @@instance = AtLeastOneReplacer.new()
end

class ItsTrueThatReplacer < GlobalReplacer
   def replace(statement)
      return statement.gsub(/it's true that /i, '')
   end

   @@instance = ItsTrueThatReplacer.new()
end

class Statement
   attr_reader(:contextPerson, :otherPerson, :statement, :expression)
   attr_accessor(:expression)

   def initialize(contextPerson, otherPerson, statement)
      @contextPerson = contextPerson
      @otherPerson = otherPerson
      @statement = GlobalReplacer::replace(statement)
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
