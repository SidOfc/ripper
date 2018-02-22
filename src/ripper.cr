require "./ripper/version"
require "./ripper/html_tags"

require "./ripper/options"
require "./ripper/selector"
require "./ripper/property"
require "./ripper/variable"

module Ripper
  extend self

  def process_selector_vars(input, vars = {} of String => Variable)
    input.gsub(/\$\{[^\}]+\}/) do |match|
      if var = vars["$" + match[2..-2]]?
        var.value
      else
        match
      end
    end
  end

  def process_vars(input, vars = {} of String => Variable)
    input.gsub(/\$[^\s,]+/) do |match|
      if var = vars[match]?
        var.value
      else
        "(#{match})"
      end
    end
  end

  def parse(content)
    root    = Selector.new ""
    parents = [root] of Selector
    commas  = [] of Selector
    vars    = {} of String => Variable

    content.split("\n").each do |line|
      next if line.empty?

      case line_type line
      when :selector
        previous = parents.last
        current  = Selector.new line

        if line.ends_with? ","
          commas << current
          next
        end

        if current.indent > previous.indent
          parents            << current
          previous.selectors << current
        else
          loop do
            if parents.empty? || current.indent > previous.indent
              parents            += parents.empty? ? [root, current] : [previous, current]
              previous.selectors << current
              break
            end

            previous = parents.pop
          end
        end

        if commas.any?
          current.commas = commas.map do |comma|
            comma.target       =  current
            previous.selectors << comma
            comma.name
          end

          commas = [] of Selector
        end
      when :property
        parents.last.properties << Property.new process_vars line, vars
      when :variable
        key, value = line.strip.split " ", 2
        vars[key]  = Variable.new key, value
      end
    end

    root.render [] of String, vars
  end

  def line_type(line : String)
    return :selector if line =~ /^\s*[+&@#.]/ || HTML_TAGS.includes?(line.strip.split(' ').first.downcase)
    return :property if line =~ /^\s*[a-z_-][\w\-]*[:\s][^;]+;?/i
    return :variable if line =~ /^\s*\$[a-z_-][\w\-]*[:\s][^;]+;?/i
    return :line
  end
end

puts Ripper.parse ARGF.gets_to_end
