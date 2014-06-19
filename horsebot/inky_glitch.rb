module HorseInky

  #
  # text glitcher
  # inspired by @negatendo_ebook
  #

  GLITCH = {
    :punctuation => [
      # ASCII
      "!*+/:=?\\^_|~".each_char.to_a,
      # C1 Controls and Latin-1 Supplement
      ("\u00A1".."\u00AC").to_a,
      ("\u00AE".."\u00BF").to_a,
      # General Punctuation
      ["\u2010"],
      ("\u2012".."\u2027").to_a,
      ("\u2030".."\u205E").to_a,
      # Spacing Modifier Letters
      ("\u02B0".."\u02FF").to_a,
      # Miscellaneous Technical
      ("\u2300".."\u23F3").to_a,
      # Control Pictures
      ("\u2400".."\u2426").to_a,
      # Optical Character Recognition
      ("\u2440".."\u244A").to_a,
      # Supplemental Punctuation
      ("\u2E00".."\u2E39").to_a,
      ("\u2E3C".."\u2E42").to_a,
      # Superscripts and Subscripts
      ("\u2070".."\u2071").to_a,
      ("\u2074".."\u208E").to_a,
      ("\u2090".."\u209C").to_a,
      # Modifier Tone Letters
      ("\uA700".."\uA71F").to_a,
    ].flatten,

    :dingbats => [
      # Miscellaneous Technical
      ("\u2300".."\u23FA").to_a,
      # Box Drawing
      ("\u2500".."\u257F").to_a,
      # Block Elements
      ("\u2580".."\u259F").to_a,
      # Geometric Shapes
      ("\u25A0".."\u25FF").to_a,
      # Miscellaneous Symbols
      ("\u2600".."\u26FF").to_a,
      # Dingbats
      ("\u2700".."\u27BF").to_a,
      # Miscellaneous Symbols and Arrows
      ("\u2B00".."\u2B4C").to_a,
      ("\u2B50".."\u2B59").to_a,
      # Yijing Hexagram Symbols
      ("\u4DC0".."\u4DFF").to_a,
      # Musical Symbols
      ("\u{1D100}".."\u{1D126}").to_a,
      ("\u{1D129}".."\u{1D158}").to_a,
      ("\u{1D15A}".."\u{1D164}").to_a,
      ("\u{1D16A}".."\u{1D16C}").to_a,
      ("\u{1D183}".."\u{1D184}").to_a,
      ("\u{1D18C}".."\u{1D1A9}").to_a,
      ("\u{1D1AE}".."\u{1D1DD}").to_a,
      # Tai Xuan Jing Symbols
      ("\u{1D300}".."\u{1D356}").to_a,
      # Mahjong Tiles
      ("\u{1F000}".."\u{1F02B}").to_a,
      # Playing Cards
      ("\u{1F0A0}".."\u{1F0AE}").to_a,
      ("\u{1F0B1}".."\u{1F0BF}").to_a,
      ("\u{1F0C1}".."\u{1F0CF}").to_a,
      ("\u{1F0D1}".."\u{1F0F5}").to_a,
      # Ornamental Dingbats
      ("\u{1F650}".."\u{1F67F}").to_a,
      # Alchemical Symbols
      ("\u{1F700}".."\u{1F773}").to_a,
    ].flatten,

    :combining => [
      # Combining Diacritical Marks
      ("\u0300".."\u034E").to_a,
      ("\u0350".."\u036F").to_a,
      # Combining Diacritical Marks for Symbols
      ("\u20D0".."\u20F0").to_a,
      # Musical Symbols
      ("\u{1D165}".."\u{1D169}").to_a,
      ("\u{1D16D}".."\u{1D172}").to_a,
      ("\u{1D17B}".."\u{1D182}").to_a,
      ("\u{1D185}".."\u{1D18B}").to_a,
    ].flatten,
  }

  def self.glitch(text)
    string = text.dup
    (GLITCH.keys.sample(rand 0..2) + [:punctuation]).each do |key|
      (rand * 0.03 * string.length).ceil.times do
        char = GLITCH[key].sample
        if key == :combining
          i = rand(string.length) + 1
          next unless string[i - 1].match /[[:alpha:]]/
        else
          i = rand(string.length + 1)
        end
        string.insert(i, char)
      end
    end
    string
  end

end
