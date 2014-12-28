# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'yaml'

module Utopia
	module Middleware
		class Content
			class Link
				XNODE_EXT = ".xnode"

				def initialize(kind, path, info = nil)
					path = Path.create(path)

					@info = info ? info : {}
					@locale = @info.delete(:locale) || path.locale(XNODE_EXT)
					@kind = kind

					case @kind
					when :file
						@name = path.basename(XNODE_EXT)
						@path = path
					when :directory
						@name = path.dirname.basename(XNODE_EXT)
						@path = path
					when :virtual
						@name = path.to_s
						@path = @info[:path] ? Path.create(@info[:path]) : nil
					end

					@components = @name.split(".")
					@title = components[0]
				end

				attr :kind
				attr :name
				attr :path
				attr :locale
				attr :info
				attr :components

				def [] (key)
					if key == :title
						return @title
					end
					
					return @info[key.to_s]
				end

				def href
					@info.fetch(:uri) do
						if @path
							@path.to_s
						else
							nil
						end
					end
				end

				def href?
					return href != nil
				end

				def title
					@info[:title] || Trenni::Strings.to_title(@title)
				end

				def to_href(options = {})
					options[:content] ||= title
					options[:class] ||= "link"
					
					if href?
						"<a class=#{options[:class].dump} href=\"#{href.to_html}\">#{options[:content].to_html}</a>"
					else
						"<span class=#{options[:class].dump}>#{options[:content].to_html}</span>"
					end
				end
				
				def eql? other
					if other && self.class == other.class
						return kind.eql?(other.kind) && 
						       name.eql?(other.name) && 
						       path.eql?(other.path) && 
						       info.eql?(other.info)
					else
						return false
					end
				end

				def == other
					return other && kind == other.kind && name == other.name && path == other.path
				end
				
				def default_locale
					@locale == ''
				end
			end
			
			module Links
				XNODE_FILTER = /^(.+)\.xnode$/
				INDEX_XNODE_FILTER = /^(index(\..+)*)\.xnode$/
				LINKS_YAML = "links.yaml"

				def self.metadata(path)
					links_path = File.join(path, LINKS_YAML)
					if File.exist?(links_path)
						return YAML::load(File.read(links_path)) || {}
					else
						return {}
					end
				end

				def self.indices(path, &block)
					entries = Dir.entries(path).delete_if{|filename| !filename.match(INDEX_XNODE_FILTER)}

					if block_given?
						entries.each &block
					else
						return entries
					end
				end

				DEFAULT_OPTIONS = {
					:directories => true,
					:files => true,
					:virtual => true,
					:indices => false,
					:sort => :order,
					:display => :display,
					:locale => nil
				}
				
				def self.index(root, top = Path.new, options = {})
					options = DEFAULT_OPTIONS.merge(options)
					path = File.join(root, top.components)
					metadata = Links.metadata(path)
					
					virtual_metadata = metadata.dup

					links = []

					Dir.entries(path).each do |filename|
						next if filename.match(/^[\._]/)

						fullpath = File.join(path, filename)

						if File.directory?(fullpath) && options[:directories]
							name = filename
							indices_metadata = Links.metadata(fullpath)
							directory_metadata = metadata.delete(name) || {}

							indices = 0
							Links.indices(fullpath) do |index|
								index_name = File.basename(index, ".xnode")
								# Values in indices_metadata will override values in directory_metadata:
								index_metadata = directory_metadata.merge(indices_metadata[index_name] || {})

								directory_link = Link.new(:directory, top + [filename, index_name], index_metadata)

								# Check for localized directory metadata and update the link:
								if directory_link.locale
									localized_metadata = metadata.delete(name + "." + directory_link.locale)

									if localized_metadata
										directory_link.info.update(localized_metadata)
									end
								end

								links << directory_link

								indices += 1
							end

							if indices == 0
								# Specify a nil uri if no index could be found for the directory:
								links << Link.new(:directory, top + [filename, ""], {'uri' => nil}.merge(directory_metadata))
							end
						elsif filename.match(INDEX_XNODE_FILTER) && options[:indices] == false
							name = $1
							metadata.delete(name)

							# We don't include indices in the list of pages.
							next
						elsif filename.match(XNODE_FILTER) && options[:files]
							name = $1

							links << Link.new(:file, top + name, metadata.delete(name))
						end
					end

					if options[:virtual]
						metadata.each do |name, details|
							# Given a virtual named such as "welcome.cn", merge it with metadata from "welcome" if it exists:
							basename, locale = name.split(".", 2)

							if virtual_metadata[basename]
								details = virtual_metadata[basename].merge(details || {})
								name = basename
								details[:locale] = locale
							end

							links << Link.new(:virtual, name, details)
						end
					end

					if options[:display]
						links = links.delete_if{|link| link[options[:display]] == false}
					end

					if options[:name]
						case options[:name]
						when Regexp
							links.reject!{|link| !link.name.match(options[:name])}
						when String
							links.reject!{|link| link.name.index(options[:name]) != 0}
						end
					end

					if options[:locale]
						reduced = []

						links.group_by(&:name).each do |name, links|
							specific = nil

							links.each do |link|
								if link.locale == options[:locale]
									specific = link
									break
								elsif link.default_locale
									specific ||= link
								end
							end

							reduced << specific if specific
						end
						
						links = reduced
					end
					
					if options[:sort]
						sort_key = options[:sort]
						sort_default = options[:sort_default] || 0
						
						links = links.sort do |a, b|
							result = nil

							lhs = a[sort_key] || sort_default
							rhs = b[sort_key] || sort_default
							
							begin
								result ||= lhs <=> rhs
							rescue
								# LOG.debug("Invalid comparison between #{a.path} and #{b.path} using key #{options[:sort]}!")
							end
							
							if result == 0 || result == nil
								a.title <=> b.title
							else
								result
							end
						end
					end
					
					return links
				end
			end
		end
	end
end