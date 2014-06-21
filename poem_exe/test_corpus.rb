require 'twitter_ebooks'
require_relative 'haiku'

model = Ebooks::Model.load 'model/haiku.model'
puts 'Ebooks:'
5.times do
  haiku = Haiku::format_haiku(model.make_statement 90)
  puts "  #{haiku}"
end

q = Haiku::Queneau.new 'corpus/haiku.json'
puts 'Queneau:'
5.times do
  haiku = Haiku::format_haiku(q.sample.join ' / ')
  puts "  #{haiku}"
end
