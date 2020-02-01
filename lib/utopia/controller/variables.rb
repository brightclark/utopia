# frozen_string_literal: true

# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Utopia
	class Controller
		# Provides a stack-based instance variable lookup mechanism. It can flatten a stack of controllers into a single hash.
		class Variables
			def initialize
				@controllers = []
			end
			
			def top
				@controllers.last
			end

			def << controller
				if top = self.top
					# This ensures that most variables will be at the top and controllers can naturally interactive with instance variables:
					controller.copy_instance_variables(top)
				end
				
				@controllers << controller
				
				return self
			end
			
			# We use self as a seninel
			def fetch(key, default=self)
				if controller = self.top
					if controller.instance_variables.include?(key)
						return controller.instance_variable_get(key)
					end
				end
				
				if block_given?
					yield(key)
				elsif !default.equal?(self)
					return default
				else
					raise KeyError.new(key)
				end
			end

			def to_hash
				attributes = {}
				
				if controller = self.top
					controller.instance_variables.each do |name|
						key = name[1..-1].to_sym
						
						attributes[key] = controller.instance_variable_get(name)
					end
				end
				
				return attributes
			end

			def [] key
				fetch("@#{key}".to_sym, nil)
			end
		end
	end
end
