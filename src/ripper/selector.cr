require "./property"
require "./variable"

module Ripper
  class Selector
    property :line, :name, :properties, :selectors, :indent, :target, :commas, :statement

    @target     : (Selector|Nil)
    @name       = ""
    @indent     = 0
    @commas     = [] of String
    @properties = [] of Property
    @selectors  = [] of Selector
    @statement  = false

    def initialize(line, **options)
      @indent     = line.partition(/^\s*/)[1].size
      @name       = line.lstrip.rstrip "{, "
      @statement  = name.starts_with? "@"
      @target     = options[:target]?
      @properties = options[:properties]? || [] of Property
      @selectors  = options[:selectors]?  || [] of Selector
    end

    def target
      @target || self
    end

    def render(names = [] of String, locals = {} of String => Variable)
      if statement
        render_statement locals do |vars|
          targets = statement ? names : names + [Ripper.process_selector_vars(name, vars)]
          content = target == self ? target.render_self(targets, vars) : ""

          content + target.selectors.map(&.render(targets, vars).as(String)).join
        end.join
      else
        targets = statement ? names : names + [name]
        content = target == self ? target.render_self(targets, locals) : ""

        content + target.selectors.map(&.render(targets, locals).as(String)).join
      end
    end

    def render_statement(locals = {} of String => Variable, &block : Hash(String, Variable) -> String)
      name, line = name.split /[ \t]+/, 2

      case Ripper.loop_type name
      when :each
        info = line.split(/using|of/i).map(&.strip)
        handle_each info.first, info.last, locals, &block
      when :loop, :iterate
        info = line.split(/using|of/i).map(&.strip)
        handle_loop info.last, info.first, locals, &block
      else [block.call(locals)]
      end
    end

    def handle_each(key, value, locals = {} of String => Variable, &block : Hash(String, Variable) -> String)
      var_key = "$" + key.strip("$")

      value.lstrip("[ ").rstrip(" ]").split(/,\s*/).map do |current_value|
        locals[var_key] = Variable.new key, Ripper.process_vars(current_value, locals)
        block.call locals
      end
    end

    def handle_loop(key, value, locals = {} of String => Variable, &block : Hash(String, Variable) -> String)
      var_key = "$" + key.strip("$")
      count   = value.gsub(/[^\d]+/, "").to_i

      count.times.map do |idx|
        locals[var_key] = Variable.new key, (idx + 1).to_s
        block.call locals
      end
    end

    def render_self(names = [] of String, locals = {} of String => Variable)
      return "" if target.properties.none? || names.empty?
      output = (commas + [names.last]).map { |n| expand(names[0..-2] + [n], locals) }.join(",\n") + " {\n"

      target.properties.each do |prop|
        prefixed_props, prefixed_vals = prop.with_prefixes
        prefixed_props.each do |prefixed_prop|
          prefixed_vals.each do |prefixed_val|
            output += "  #{prefixed_prop}: #{prefixed_val};\n"
          end
        end
      end

      output + "}\n"
    end

    def expand(names = [] of String, locals = {} of String => Variable)
      selector = ""
      ending   = ""

      names.each do |name|
        tmp = Ripper.process_selector_vars name, locals
        case tmp
        when /^(?:&?\s*\+\s*&|&&)$/
          selector += " + #{ending.strip}"
        when /^&/
          selector += ending = tmp.tr "&", ""
        when /&$/
          ending   = tmp.tr "&", ""
          selector = ending + selector.lstrip
        when /&/
          selector = tmp.sub "&", selector.strip
          ending   = selector.split(" ").last
        else
          selector += ending = " #{tmp}"
        end
      end

      selector.strip
    end
  end
end
