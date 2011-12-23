require '../lib/extra_loop'

results = []

IterativeScraper.new("https://www.google.com/search?tbm=nws&q=Egypt", :log => {
  :log_level => :debug,
  :appenders => [Logging.appenders.stderr ]
}).set_iteration(:start, (1..101).step(10)).
   loop_on("h3", proc { |nodes| nodes.map(&:parent) }).
     extract(:title, "h3.r a").
     extract(:url, "h3.r a", :href).
     extract(:source, "br", proc { |node|
       node.next.text.split("-").first
     }).
   set_hook(:on_data, proc { |data, response|
     data.each { |record| results << record }
   }).
   run()

results.each_with_index do |record, index|
  puts "#{index}) #{record.title} (source: #{record.source})"
end