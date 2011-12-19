require 'parslet'

module Nagix
	class NQLParser < Parslet::Parser
 	  def stri(str)
      key_chars = str.split(//)
      key_chars.collect! { |char| match["#{char.upcase}#{char.downcase}"] }.reduce(:>>)
    end

		rule(:whitespace?)    { match('\s+').maybe }
		rule(:quote)          { str("'") }
  	rule(:nonquote)       { str("'").absnt? >> any }
  	rule(:escape)         { str('\\') >> any }

		rule(:select)         { stri('SELECT') >> whitespace? }
		rule(:from)           { stri('FROM') >> whitespace? }
		rule(:where)          { stri('WHERE') >> whitespace? }
		rule(:and_op)         { stri('AND') >> whitespace? }
		rule(:or_op)          { stri('OR') >> whitespace? }
		rule(:star_op)        { str('*').as(:all) }
  	rule(:lparen) 			  { str("(") >> whitespace? }
  	rule(:rparen) 			  { str(")") >> whitespace? }

		rule(:operator)       { str('=') | str('!=') | str('>=') | str('<=') | str('>') | str('<') }
		rule(:identifier)     { match('[A-Za-z0-9_]').repeat(1) }
		rule(:string)         { quote >> (escape | nonquote).repeat(1).as(:str) >> quote }
		rule(:integer)        { (str('+') | str('-')).maybe >> match('[0-9]').repeat(1) }
		rule(:float)          { integer >> (str('.') >> match('[0-9]').repeat(1) | str('e') >> match('[0-9]').repeat(1)) }
		rule(:literal)        { string | float.as(:float) | integer.as(:integer) }

		rule(:table)          { identifier.as(:table) >> whitespace? }
		rule(:some_columns)   { identifier.as(:column) >> whitespace? >> (str(',') >> whitespace? >> identifier.as(:column) >> whitespace?).repeat }
		rule(:columns)        { star_op | some_columns }
		rule(:expression)     { identifier.as(:identifier) >> whitespace? >> operator.as(:op) >> whitespace? >> literal.as(:expression) >> whitespace? }
		rule(:is_null)        { identifier.as(:identifier) >> whitespace? >> str('is') >> whitespace? >> str('null') >> whitespace? }
		rule(:condition)      { lparen >> or_conditions >> rparen | expression | is_null.as(:is_null) }
		rule(:and_conditions) { (condition.as(:left) >> and_op >> and_conditions.as(:right)).as(:and) | condition }
		rule(:or_conditions)  { (and_conditions.as(:left) >> or_op >> or_conditions.as(:right)).as(:or) | and_conditions }
		rule(:conditions)     { or_conditions }
		rule(:where_clause)   { where >> conditions.as(:conditions) }
		rule(:query)          { (select >> columns.as(:columns) >> whitespace? >> from >> table >> where_clause.maybe).as(:query) }

		root :query
	end

	class NQLTransformer < Parslet::Transform
		rule(:str => simple(:str)) { String(str) }
		rule(:integer => simple(:integer)) { Integer(integer) }
		rule(:float => simple(:float)) { Float(float) }

		rule(:column => simple(:column)) { String(column) }

		rule(:identifier => simple(:identifier), :op => simple(:op), :expression => subtree(:expression)) { "\nFilter: #{identifier} #{op} #{expression}" }
		rule(:is_null => { :identifier => simple(:identifier) }) { "\nFilter: #{identifier}" }
		rule(:and => { :left => subtree(:left), :right => simple(:right) }) { "#{left}#{right}\nAnd: 2" }
		rule(:or => { :left => subtree(:left), :right => simple(:right) }) { "#{left}#{right}\nOr: 2" }

		rule(:conditions => sequence(:condition)) { "#{condition.join}" }

		rule(:table => simple(:table),
		     :columns => sequence(:columns),
		     :conditions => subtree(:conditions)) { "GET #{table}\nResponseHeader: fixed16\nColumns: #{columns.join(' ')}\nColumnHeaders: on#{conditions}\n" }
		rule(:table => simple(:table),
		     :columns => { :all => simple(:all) },
		     :conditions => subtree(:conditions)) { "GET #{table}\nResponseHeader: fixed16#{conditions}\n" }
		rule(:table => simple(:table),
		     :columns => sequence(:columns)) { "GET #{table}\nResponseHeader: fixed16\nColumns: #{columns.join(' ')}\nColumnHeaders: on\n"  }
		rule(:table => simple(:table),
		     :columns => { :all => simple(:all) }) { "GET #{table}\nResponseHeader: fixed16\n" }

    rule(:query => subtree(:query)) { String(query) }
	end

	class NQL
		def initialize
			@parser = NQLParser.new
			@transformer = NQLTransformer.new
		end

		def parse(query)
			begin
				ast = @parser.parse(query)
				#require 'pp'
				#pp ast
        @transformer.apply(ast)
      rescue Parslet::ParseFailed => error
        puts error, @parser.root.error_tree
      end
		end
	end
end
