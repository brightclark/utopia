#!/usr/bin/env rspec
# frozen_string_literal: true

# Copyright, 2015, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'utopia/content/markup'

module Utopia::Content::MarkupSpec
	class TestDelegate
		def initialize
			@events = []
		end
		
		attr :events
		
		def method_missing(*arguments)
			@events << args
		end
	end
	
	describe Utopia::Content::MarkupParser do
		it "should format open tags correctly" do
			foo_tag = Utopia::Content::Tag.opened("foo", bar: true, baz: 'bob')
			
			expect(foo_tag[:bar]).to be == true
			expect(foo_tag[:baz]).to be == 'bob'
			
			expect(foo_tag.to_s('content')).to be == '<foo bar baz="bob">content</foo>'
		end
		
		def parse(string)
			delegate = TestDelegate.new
			
			buffer = Trenni::Buffer.new(string)
			Utopia::Content::MarkupParser.new(buffer, delegate).parse!
			
			return delegate
		end
		
		it "should parse single tag" do
			
			delegate = parse %Q{<foo></foo>}
			
			foo_tag = Utopia::Content::Tag.opened("foo")
			expected_events = [
				[:tag_begin, foo_tag],
				[:tag_end, foo_tag],
			]
			
			expect(delegate.events).to be == expected_events
			
			expect(foo_tag.to_s)
		end
		
		it "should parse and escape text" do
			delegate = parse %Q{<foo>Bob &amp; Barley<!-- Comment --><![CDATA[Hello & World]]></foo>}
			
			foo_tag = Utopia::Content::Tag.opened("foo")
			expected_events = [
				[:tag_begin, foo_tag],
				[:text, "Bob & Barley"],
				[:write, "<!-- Comment -->"],
				[:write, "<![CDATA[Hello & World]]>"],
				[:tag_end, foo_tag],
			]
			
			expect(delegate.events).to be == expected_events
		end
		
		it "should fail with incorrect closing tag" do
			expect{parse %Q{<p>Foobar</dl>}}.to raise_exception(Utopia::Content::MarkupParser::UnbalancedTagError)
		end
		
		it "should fail with unclosed tag" do
			expect{parse %Q{<p>Foobar}}.to raise_exception(Utopia::Content::MarkupParser::UnbalancedTagError)
		end
	end
end
