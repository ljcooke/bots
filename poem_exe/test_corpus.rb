require 'twitter_ebooks'
require_relative 'haiku'

model = Ebooks::Model.load 'model/haiku.model'
puts 'Ebooks:'
10.times do
  lines = model.make_statement(90).split('/').map(&:strip)
  haiku = Haiku::format_haiku(lines.join("\n"), :single_line => true)
  puts "  #{haiku}"
end

q = Haiku::Queneau.new 'corpus/haiku.json'
puts 'Queneau:'
20.times do
  lines = q.sample
  haiku = Haiku::format_haiku(lines.join("\n"), :single_line => true)
  puts "  #{haiku}"
end
