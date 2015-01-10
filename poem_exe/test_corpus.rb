require 'date'
require_relative 'poem'

p = PoemExe::Poet.new 'haiku'

(1..12).each do |month|
  puts Date::MONTHNAMES[month]
  3.times do
    poem = p.make_poem(single_line: true, month: month)
    puts "    #{poem}"
  end
  puts ""
end
