#!/usr/bin/env ruby
# encoding: utf-8

module HorseInky
  #
  # Transform text using a variety of methods.
  #

  PUNCTUATION = ".,…:;?!'\"()[]<>/\\“”‘’*|-=–—+#".chars.to_a

  CYRILLIC_UPPER = "АБВГҐДЕЄЖЗЅZИЙІЈКЛЉМНЊОПРСТЋУФХЦЧЏШЩЪЫЬЭЮЯ".chars.to_a
  CYRILLIC_LOWER = "абвгґдеєжзѕzийіјклљмнњопрстћуфхцчџшщъыьэюя".chars.to_a
  GREEK_UPPER = "ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΪΫ".chars.to_a
  GREEK_LOWER = "αβγδεζηθικλμνξοπρστυφχψωϊϋ".chars.to_a + ["ς"]
  LATIN_UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZÆŒÞ".chars.to_a + "ƆƎƝƟƧ".chars.to_a
  LATIN_LOWER = "abcdefghijklmnopqrstuvwxyzæœþ".chars.to_a

  LANGS = {

    "APL" => {
      :letters =>
        ("\u2336".."\u2357").to_a +
        (("\u235D".."\u2372").to_a - "\u236A\u236E".chars.to_a),
    },

    "Arabic" => {
      :letters =>
        ("\u0621".."\u063F").to_a +
        ("\u0641".."\u064A").to_a +
        ("\u0750".."\u077F").to_a,
      :keep_punctuation => true,
    },

    "Bengali" => {
      :letters =>
        (("\u0985".."\u0994").to_a - "\u098D\u098E\u0991\u0992".chars.to_a) +
        ("\u0995".."\u09A8").to_a +
        ("\u09AA".."\u09B0").to_a +
        ["\u09B2"] +
        ("\u09B6".."\u09B9").to_a +
        "\u09BD\u09CE\u09DC\u09DD\u09DF\u09E0\u09E1\u09F0\u09F1".chars.to_a
    },

    "Block Elements" => {
      :letters =>
        "░▒▓█".chars.to_a +
        "▕▁▔▏▀▄".chars.to_a +
        ("\u2596".."\u259F").to_a,
      :chance => 0.5,
    },

    "Box Drawing: Thin Horizontal Line" => {
      :letters =>
        "─┬┴┼╥╨╫".chars.to_a,
      :punctuation =>
        "╱╲╳╵╷".chars.to_a,
    },

    "Cherokee" => {
      :letters =>
        ("\u13A0".."\u13F4").to_a,
      :keep_punctuation => true,
    },

    "CJK: Bopofomo + Katakana Extensions for Ainu + Misc" => {
      :letters =>
        ("\u3105".."\u3129").to_a +
        ("\u31F0".."\u31FF").to_a +
        "〡〢〣〤〦〧〨〩卄卅".chars.to_a,
      :space => '',
    },

    "CJK: Chinese" => {
      :letters =>
        ("\u4E00".."\u9FCC").to_a,
      :space => '',
    },

    "CJK: Hangul" => {
      :letters =>
        ("\uAC00".."\uD7A3").to_a,
    },

    "CJK: Hangul, symmetric subset" => {
      :letters =>
        ("모몸몹못몼몽몾몿뫂묘묨묩묫묬묭묮묯묲"
         "무뭄뭅뭇뭈뭉뭊뭋뭎뮤뮴뮵뮷뮸뮹뮺뮻뮾"
         "므믐믑믓믔믕믖믗믚보봄봅봇봈봉봊봋봎"
         "뵤뵴뵵뵷뵸뵹뵺뵻뵾부붐붑붓붔붕붖붗붚"
         "뷰븀븁븃븄븅븆븇븊브븜븝븟븠븡븢븣븦"
         "뽀뽐뽑뽓뽔뽕뽖뽗뽚뾰뿀뿁뿃뿄뿅뿆뿇뿊"
         "뿌뿜뿝뿟뿠뿡뿢뿣뿦쀼쁌쁍쁏쁐쁑쁒쁓쁖"
         "쁘쁨쁩쁫쁬쁭쁮쁯쁲소솜솝솟솠송솢솣솦").chars.to_a,
    },

    "CJK: HEHEHE" => {
      # https://twitter.com/rumnogg/status/551819765799337984
      :letters => "ㅐ태탵".chars.to_a,
    },

    "CJK: Radicals" => {
      :letters =>
        ("\u2F00".."\u2FD5").to_a,
      :space => "・",
    },

    "Cyrillic" => {
      :upper => CYRILLIC_UPPER,
      :lower => CYRILLIC_LOWER,
      :keep_punctuation => true,
    },

    "Cyrillic/Greek/Latin blend" => {
      :upper => CYRILLIC_UPPER + GREEK_UPPER + LATIN_UPPER,
      :lower => CYRILLIC_LOWER + GREEK_LOWER + LATIN_LOWER,
      :keep_punctuation => true,
      :chance => 0.5,
    },

    "Cyrillic/Greek/Latin no ascenders or descenders" => {
      :letters =>
        "acemnorsuvwxzæœαεικπστυωвгєжзиклљмнњптчшъыьэюя".chars.to_a,
    },

    "Cyrillic/Greek/Latin straight lines" => {
      :letters =>
        "AEFHIKLMNTVWXYZÆƎΓΔΛΞΠΣИШ⅂⅃⅄Ⅎ".chars.to_a,
    },

    "Cyrillic/Greek/Latin symmetric" => {
      :upper =>
        "AHIMOTVWXЖПФШΔΘΛΞΨΩ".chars.to_a,
      :lower =>
        "iılovwxжмнпфшθχω".chars.to_a,
    },

    "Devanagari" => {
      :letters =>
        ("\u0904".."\u0939").to_a +
        ("\u0958".."\u0961").to_a +
        "\u093D\u0950\u0972".chars.to_a,
    },

    "Emoji: Circular without faces" => {
      :letters =>
        ("🌀🌍🌎🌏🌐🌑🌒🌓🌔🌕🌖🌗🌘🍅🍊🍘🍥🍪🎯🎱🎾🏀💮💿📀📵🔘🔴🔵"
         "🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕜🕝🕞🕟🕠🕡🕢🕣🕤🕥🕦🕧🚇🚯🚱🚳🚷⚽⛔").chars.to_a,
      :space => '⚫',
    },

    "Georgian" => {
      :letters =>
        ("\u10D0".."\u10FF").to_a,
      :keep_punctuation => true,
    },

    "Greek" => {
      :upper => GREEK_UPPER,
      :lower => GREEK_LOWER,
      :keep_punctuation => true,
    },

    "Kaleidoscopic Runes" => {
      :letters =>
        "◎△◦◯¤※✢✣✥✧✩✺✻✼❅❆❈❉❊❋†‡‖".chars.to_a,
    },

    "Khmer" => {
      :letters =>
        ("\u1780".."\u17A2").to_a +
        ("\u17A5".."\u17B3").to_a +
        ("\u17E0".."\u17E9").to_a +
        ["\u17D8"],
      :punctuation =>
        (("\u17D4".."\u17DA").to_a - ["\u17D8"]) +
        ["\u17DB"],
      :space => '',
    },

    "Khmer symbols" => {
      :upper =>
        "។៖ៗ៙៚៛១២៣៤៥៦៧៨៩".chars.to_a,
      :lower =>
        "៰៱៲៳៴៵៶៷៸៹".chars.to_a,
    },

    "Latin" => {
      :upper => LATIN_UPPER,
      :lower => LATIN_LOWER,
      :keep_punctuation => true,
      :chance => 0.5,
    },

    "Modifier Tone Letters" => {
      :letters =>
        ("\uA708".."\uA716").to_a,
      :punctuation =>
        ("\uA700".."\uA707").to_a +
        ("\uA717".."\uA71F").to_a,
    },

    "Mongolian" => {
      :letters =>
        ("\u1820".."\u1877").to_a +
        ("\u1880".."\u18A8").to_a,
      :punctuation =>
        ("\u1800".."\u180A").to_a,
    },

    "Ogham" => {
      :letters =>
        (("\u1681".."\u1694").to_a * 2) +
        ("\u1695".."\u169A").to_a,
      :space => "\u1680",
      :prefix => "\u169B",
      :suffix => "\u169C",
    },

    "Optical Character Recognition" => {
      :letters =>
        ("\u2440".."\u2444").to_a,
      :punctuation =>
        ("\u2445".."\u244A").to_a,
    },

    "Phonetic Extensions" => {
      :letters =>
        ("\u1d00".."\u1d7f").to_a,
      :chance => 0.5,
    },

    "Unified Canadian Aboriginal Syllabics" => {
      :letters =>
        ("\u1401".."\u166C").to_a,
    },

    "Tai Xuan Jing Symbols" => {
      :letters =>
        ("\u{1D306}".."\u{1D356}").to_a,
      :punctuation =>
        ("\u{1D300}".."\u{1D305}").to_a,
    },

    "Yi Syllables + Radicals" => {
      :letters =>
        ("\uA000".."\uA48C").to_a,
      :punctuation =>
        (("\uA490".."\uA4C4").to_a - "\uA4A2\uA4A3\uA4B4\uA4C1".chars.to_a)
    },

    "Yijing Hexagram Symbols" => {
      :letters =>
        ("\u4DC0".."\u4DFF").to_a,
    },

  }

  def self.demo(text)
    LANGS.keys.map do |key|
      self.transform(text, key)
    end
  end

  def self.transform(text, key=nil)
    lang = key || LANGS.keys.sample
    attrs = LANGS[lang]

    if attrs.has_key? :upper and attrs.has_key? :lower
      self.transform_case_sensitive(text, attrs)
    else
      self.transform_chars(text, attrs)
    end
  end

  def self.transform_case_sensitive(text, attrs)
    upper = attrs[:upper]
    lower = attrs[:lower]
    letters = upper + lower
    punc = attrs[:punctuation]
    keep_punc = attrs[:keep_punctuation]
    chance = attrs[:chance]

    new_text = text.split.map { |word|
      word.chars.map { |c|

        next c if chance and rand < chance

        if PUNCTUATION.member? c
          next c unless keep_punc.nil?
          next punc.sample unless punc.nil?
        end

        if c.upcase != c.downcase
          # uppercase or lowercase letter
          c == c.upcase ? upper.sample : lower.sample
        else
          # any other character
          letters.sample
        end

      }.join('')
    }.join(' ')
    self.wrap_transformation(new_text, attrs)
  end

  def self.transform_chars(text, attrs)
    letters = attrs[:letters]
    punc = attrs[:punctuation]
    keep_punc = attrs[:keep_punctuation]
    space = attrs[:space] || ' '
    chance = attrs[:chance]

    new_text = text.split.map { |word|
      word.chars.map { |c|

        next c if chance and rand < chance

        if PUNCTUATION.member? c
          next c unless keep_punc.nil?
          next punc.sample unless punc.nil?
        end

        letters.sample

      }.join('')
    }.join(space)
    self.wrap_transformation(new_text, attrs)
  end

  def self.wrap_transformation(text, attrs)
    prefix = attrs[:prefix] || ''
    suffix = attrs[:suffix] || ''
    "#{prefix}#{text}#{suffix}"
  end

end

if ARGV.include? '--test'
  typical_tweet = 'an update in my Bandcamp feed: "Various Artists released an album."'
  HorseInky::demo(typical_tweet).each do |text|
    puts text
  end
end
