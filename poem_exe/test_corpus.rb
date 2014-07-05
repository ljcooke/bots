require_relative 'poem'

p = PoemExe::Poet.new 'haiku'
20.times do
  puts p.make_poem(:single_line => true)
end
