require "./ripper/*"

module Ripper
  extend self

  class Selector
    property :line, :name, :properties, :selectors, :parent, :indent

    @parent     : (Selector|Nil)
    @line       : String
    @indent     : Int32
    @name       : String
    @root       : Bool
    @properties : Array(String)
    @selectors  : Array(Selector)
    @expanded   : String = ""

    def initialize(@line, **options)
      @name       = @line.lstrip
      @parent     = options[:parent]?
      @root       = options[:root]? ? true : false
      @properties = options[:properties]? || [] of String
      @selectors  = options[:selectors]?  || [] of Selector
      @indent     = @line.partition(/^\s*/)[1].size
    end

    # .hello
    #   & .there        => .hello .there { ... }
    #   &.there         => .hello.there { ... }
    #   .there & .here  => .there .hello .there { ... }

    def expand2
      if name.starts_with? '&'
      elsif name.ends_with? '&'
      elsif name.contains? '&'
      end
    end

    def name2
      tmp_parent = parent
      return name unless tmp_parent
      return [tmp_parent.name2, name.tr("&", "")] if name.starts_with?('&')
    end

    def expand
      names = [] of String
      npar  = parent
      eamp  = name.ends_with? '&'
      names << name unless eamp

      loop do
        break unless npar
        break if     npar.root?

        names << npar.name
        npar   = npar.parent
      end

      names << name if eamp
      names.reverse!

      names.join.tr "&", ""
    end

    def root?
      @root
    end
  end

  def line_type(line : String)
    return :comment   if line =~ /^(?:#\s|\s*\/\*)/
    return :selector  if line =~ /^\s*[&#.]/
    :property
  end

  def parse(content : String)
    root            = Selector.new ":root", root: true
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
        last_selector.properties << line
      when :comment
      end
    end

    format root
  end

  def format(selector : Selector)
    result = ""

    unless selector.root? || selector.properties.none?
      puts selector.name2
      result += selector.expand + " {\n"
      selector.properties.each do |prop|
        result += "  " + prop.lstrip + ";\n"
      end
      result += "}\n"
    end

    if (selector.selectors.any?)
      selector.selectors.each do |selector|
        result += format selector
      end
    end

    result
  end
end

SAMPLE  = File.read File.join(__DIR__, "../", "spec", "files", "input.rip")

puts Ripper.parse SAMPLE

