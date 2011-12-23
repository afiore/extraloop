require '../lib/extra_loop'

wikipedia_baseurl = "http://en.wikipedia.org"
endpoint_url = "/w/api.php"
api_url = wikipedia_baseurl + endpoint_url
all_results = []

params = {
  :action => 'query',
  :list => 'categorymembers',
  :format => 'json',
  :cmtitle => 'Category:Linguistics',
  :cmlimit => "100",
  :cmtype => 'page|subcat',
  :cmdir => 'asc',
  :cmprop => 'ids|title|type|timestamp'
}
options = {
  :format => :json,
  :log => {
    :appenders => [Logging.appenders.stderr],
    :log_level => :info
  }
}
request_arguments = { :params => params }


#
# Fetches members of the English wikipedia's category "Linguistics".
#
# This uses the the #continue_with instead of the #set_iteration method 
# (used in the Google News example).
#

IterativeScraper.new(api_url, options, request_arguments).
  loop_on(proc { |doc| doc['query']['categorymembers'] }).
    extract(:title).
    extract(:ns).
    extract(:type).
    extract(:timestamp).
  set_hook(:on_data, proc { |results|
    results.each { |record| all_results << record }
  }).
  continue_with(:cmcontinue, proc { |doc, response| 
    doc['query-continue']['categorymembers']['cmcontinue'] if doc['query-continue'] 
  }).
  run()

puts "#{all_results.size} fetched"

