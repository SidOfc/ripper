module Ripper
  module Prefixed
    extend self

    def [](name, value : String)
      {prop(name), val(value)}
    end

    def [](name, value : Nil)
      {prop(name), val("")}
    end

    def prop(name)
      return [name] unless properties.includes? name

      tmp  = names.map { |n| "-#{n}-#{name}" }
      tmp << name
      tmp
    end

    def val(value)
      return [value] unless values.includes? value

      tmp  = names.map { |n| "-#{n}-#{value}" }
      tmp << value
      tmp
    end

    def properties
      PREFIXED_PROPERTIES
    end

    def values
      PREFIXED_VALUES
    end

    def names
      PREFIXES
    end
  end

  PREFIXES = %w[
    o ms moz webkit
  ]

  PREFIXED_VALUES = %w[
    linear-gradient()
    radial-gradient()
    repeating-linear-gradient()
    repeating-radial-gradient()
    grab
    grabbing
    sticky
]

  PREFIXED_PROPERTIES = %w[
    border-radius
    border-top-left-radius
    border-top-right-radius
    border-bottom-right-radius
    border-bottom-left-radius
    animation
    animation-name
    animation-duration
    animation-delay
    animation-direction
    animation-fill-mode
    animation-iteration-count
    animation-play-state
    animation-timing-function
    transition
    transition-property
    transition-duration
    transition-delay
    transition-timing-function
    transform
    transform-origin
    perspective
    perspective-origin
    transform-style
    backface-visibility
    columns
    column-width
    column-gap
    column-rule
    column-rule-color
    column-rule-width
    column-count
    column-rule-style
    column-span
    column-fill
    break-before
    break-after
    break-inside
    display
    flex
    flex-grow
    flex-shrink
    flex-basis
    flex-direction
    flex-wrap
    flex-flow
    justify-content
    order
    align-items
    align-self
    align-content
    background-clip
    background-origin
    background-size
    font-feature-settings
    font-variant-ligatures
    font-language-override
    font-kerning
    max-content
    min-content
    fit-content
    zoom-in
    zoom-out
    text-decoration-style
    text-decoration-line
    text-decoration-color
    clip-path
    mask
    mask-clip
    mask-composite
    mask-image
    mask-origin
    mask-position
    mask-repeat
    mask-size
    shape-outside
    shape-image-threshold
    shape-margin
  ]
end
