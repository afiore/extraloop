require '../lib/extraloop'

class WikipediaCategoryScraper < ExtraLoop::IterativeScraper
  attr_accessor :members
  attr_reader   :request_arguments

  baseurl = "http://en.wikipedia.org"
  endpoint_url = "/w/api.php"
  @@api_url = baseurl + endpoint_url

  def initialize(category, depth=2, parent=nil)

    @members = []
    @parent  = parent

    params = {
      :action => 'query',
      :list => 'categorymembers',
      :format => 'json',
      :cmtitle => "Category:#{category.gsub(/^Category\:/,'')}",
      :cmlimit => "100",
      :cmtype => 'page|subcat',
      :cmdir => 'asc',
      :cmprop => 'ids|title|type|timestamp'
    }
    options = {
      :depth => depth,
      :format => :json,
      :log => false
    }
    request_arguments = { :params => params }

    super(@@api_url, options, request_arguments)

    loop_on(['query', 'categorymembers']).
      extract(:title).
      extract(:ns).
      extract(:type).
      extract(:timestamp).
    on(:data, proc { |results|
      categories = results.select{ |record| record.ns === 14  }.each { |category| results.delete(category) }

      results.each do |record|
      end

      categories.each do |record|
        # Instanciate a sub scraper if the current depth is greater than zero
        # and the category member is a sub category.
        WikipediaCategoryScraper.new(record.title, @options[:depth] - 1, @scraper.request_arguments[:params][:cmtitle] ).run unless @options[:depth] <= 0
      end

    }).
    continue_with(:cmcontinue, ['query-continue', 'categorymembers', 'cmcontinue'])
  end
end


WikipediaCategoryScraper.new("Italian_media").run
