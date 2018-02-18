require "./ripper/version"
require "./ripper/html_tags"

require "./ripper/selector"
require "./ripper/property"

module Ripper
  extend self

  def parse(content : String)
    root            = Selector.new "", root: true
    last_selector   = root
    last_sel_indent = 0

    content.split("\n").each do |line|
      next if line.empty?

      case line_type line
      when :selector
        current = Selector.new line

        if current.indent > last_selector.indent
          current.parent = last_selector
          last_selector.selectors << current
        elsif current.indent <= last_selector.indent
          if pls = last_selector.parent
            loop do
              if pls.root? || current.indent > pls.indent
                current.parent = pls
                pls.selectors << current
                break
              end

              break unless pls = pls.parent
            end
          else
            current.parent = root
            root.selectors << current
          end
        end

        last_selector = current
      when :property
        last_selector.properties << Property.new line
      when :comment, :close_bracket
      end
    end

    root.render
  end

  def line_type(line : String)
    return :close_bracket if line =~ /^\s*\}/
    return :comment       if line =~ /^(?:#\s|\s*\/\*|\/\/)/
    return :selector      if line =~ /^\s*[&#.]/ || HTML_TAGS.includes? line.strip.split(' ')[0].downcase
    :property
  end
end

puts Ripper.parse "
.hello
  cursor: grab;
  border-radius: 10px;
"
