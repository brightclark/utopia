# frozen_string_literal: true

# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'utopia/content/document'

RSpec.describe Utopia::Content::Document do
	subject{described_class.new(nil, {})}
	
	it "should generate valid self-closing markup" do
		node = proc do |document, state|
			subject.tag("img", src: "cats.jpg")
		end
		
		result = subject.render_node(node)
		
		expect(result).to be == '<img src="cats.jpg"/>'
	end
	
	it "should generate valid nested markup" do
		node = proc do |document, state|
			subject.tag("div") do
				subject.tag("img", src: "cats.jpg")
			end
		end
		
		result = subject.render_node(node)
		
		expect(result).to be == '<div><img src="cats.jpg"/></div>'
	end
	
	it "should fail if tags are unbalanced" do
		node = proc do |document, state|
			div = Utopia::Content::Tag.opened('div')
			span = Utopia::Content::Tag.opened('span')
			subject.tag_begin(div)
			subject.tag_end(span)
		end
		
		expect{subject.render_node(node)}.to raise_error Utopia::Content::UnbalancedTagError, /tag span/
	end
end
