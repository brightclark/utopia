
require 'active_support'

class Date
	alias_method :old_cmp, :<=>
	
	def <=> (other)
		# Comparing a Date with something that has a time component truncates the time
		# component, thus we need to check if the other object has a more exact comparison
		# function.
		if other.respond_to?(:hour)
			return (other <=> self) * -1
		else
			old_cmp(other)
		end
	end	
end

class String
	HTML_ESCAPE = {"&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "\"" => "&quot;"}
	HTML_ESCAPE_PATTERN = Regexp.new("[" + Regexp.quote(HTML_ESCAPE.keys.join) + "]")

	def to_html
		gsub(HTML_ESCAPE_PATTERN){|c| HTML_ESCAPE[c]}
	end

	def to_title
		(" " + self).gsub(/[ \-_](.)/){" " + $1.upcase}
	end

	def to_snake
		self.gsub("::", "").gsub(/([A-Z]+)/){"_" + $1.downcase}.sub(/^_+/, "")
	end
end

class Hash
	def symbolize_keys
		inject({}) do |options, (key, value)|
			options[(key.to_sym rescue key) || key] = value
			options
		end
	end
end

class Array
	def find_index(&block)
		each_with_index do |item, index|
			if yield(item)
				return index
			end
		end
		
		return nil
	end
	
	def split_at(&block)
		index = find_index(&block)
		
		if index
			return [self[0...index], self[index], self[index+1..-1]]
		end
		
		return [[], nil, []]
	end
end

if defined? Rack
	class Rack::Request
		def self.new(*args)
			super(*args)
		end
	end
end
