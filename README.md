# Extra Loop

A Ruby library for extracting structured data from websites and web based APIs. 
Supports most common document formats (i.e. HTML, XML, CSV, and JSON), and comes with a handy mechanism 
for iterating over paginated datasets.

## Installation:

    gem install extraloop

## Usage:

A basic scraper that fetches the top 25 websites from [Alexa's daily top 100](www.alexa.com/topsites) list:

    alexa_scraper = ExtraLoop::ScraperBase.
      new("http://www.alexa.com/topsites").
      loop_on("li.site-listing").
        extract(:site_name, "h2").
        extract(:url, "h2 a").
        extract(:description, ".description").
      on(:data) { |data| { |record| puts record.site_name } }

    alexa_scraper.run

An iterative Scraper that fetches URL, title, and publisher from some 110 Google News articles mentioning the keyword _'Egypt'_.

    results = []

    ExtraLoop::IterativeScraper.
      new("https://www.google.com/search?tbm=nws&q=Egypt").
      set_iteration(:start, (1..101).step(10)).
      loop_on("h3") { |nodes| nodes.map(&:parent) }.
        extract(:title, "h3.r a").
        extract(:url, "h3.r a", :href).
        extract(:source, "br") { |node| node.next.text.split("-").first }.
      on(:data) { |data, response| data.each { |record| results << record } }.
      run()


## Scraper initialisation signature

    #new(urls, scraper_options, http_options)

- __urls__ - single url, or array of several urls.
- __scraper_options__ - hash of scraper options (see below).
- __http_options__ - hash of request options for `Typheous::Request#initialize` (see [API documentation](http://rubydoc.info/github/pauldix/typhoeus/master/Typhoeus/Request#initialize-instance_method) for details).

### scraper options:

* __format__ - Specifies the scraped document format; needed only if the Content-Type in the server response is not the correct one. Supported formats are: 'html', 'xml', 'json', and 'csv'. 
* __async__ - Specifies whether the scraper's HTTP requests should be run in parallel or in series (defaults to false). **Note:** currently only GET requests can be run asynchronously.
* __log__ - Logging options hash:
     * __loglevel__  - a symbol specifying the desired log level (defaults to `:info`).
     * __appenders__ - a list of Logging.appenders object (defaults to `Logging.appenders.sterr`).

## Extractors

ExtraLoop allows to fetch structured data from online documents by looping through a list of elements matching a given selector.
For each matched element, an arbitrary set of fields can be extracted. While the `loop_on` method sets up such loop, the `extract` 
method extracts a specific piece of information from an element (e.g. a story's title) and stores it into a record's field.

    # looping over a set of document elements using a CSS3 (or XPath) selector
    loop_on('div.post')

    # looping 

    loop_on { |doc| doc.search('div.post') }

    # using both a selector and a proc (the matched element list is passed in to the proc as its first argument )

    loop_on('div.post') { |posts| posts.reject { |post| post.attr(:class) == 'sticky' } }

Both the `loop_on` and the `extract` methods may be called with a selector, a block or a combination of the two. By default, when parsing DOM documents, `extract` will call
`Nokogiri::XML::Node#text()`. Alternatively, `extract` also accepts an attribute name and a block. The latter is evaluated in the context of the current iteration's element. 

    # extract a story's title 
    extract(:title, 'h3')

    # extract a story's url
    extract(:url, "a.link-to-story", :href)

    # extract a description text, separating paragraphs with newlines 
    extract(:description, "div.description") { |node| node.css("p").map(&:text).join("\n") }

### Extracting data from JSON Documents

While processing an HTTP response, ExtraLoop tries to automatically detect the scraped document format by looking at 
the `ContentType` header sent by the server. This value can be overriden by providing a `:format` key in the scraper's 
initialization options. When format is JSON, the document is parsed using the `yajl` JSON parser and converted into a hash. 
In this case, both the `loop_on` and the `extract` methods still behave as illustrated above, except it does not support 
CSS3/XPath selectors.

When working with JSON data, you can just use a block and have it return the document elements you want to loop on.

    # Fetch a portion of a document using a proc
    loop_on  { |data| data['query']['categorymembers'] })

Alternatively, the same loop can be defined by passing an array of keys pointing at a hash value located 
at several levels of depth down into the parsed document structure.

    # Same as above, using a hash path
    loop_on(['query', 'categorymembers'])

When fetching fields from a JSON document fragment, `extract` will often not need a block or an array of keys. If called with only
one argument, it will in fact try to fetch a hash value using the provided field name as key.

    # current node:
    #
    # {
    #  'from_user' => "johndoe", 
    #  'text' => 'bla bla bla',
    #  'from_user_id'..
    # }

    # >> extract(:from_user)
    # => "johndoe"


## Iteration methods

The `IterativeScraper` class comes with two methods that allow scrapers to loop over paginated content.

### set\_iteration

* __iteration_parameter__ - A symbol identifying the request parameter that the scraper will use as offset in order to iterate over the paginated content.
* __array_or_range_or_block__ - Either an explicit set of values or a block of code. If provided, the block is called with the parsed document object as its first argument. The block should return a non empty array, which will determine the value of the offset parameter during each iteration. If the block fails to return a non empty array, the iteration stops.

### continue\_with

The second iteration method, `#continue_with`, allows to continue an interation as long as a block of code returns a truthy, non-nil value (to be assigned to the iteration parameter).

* __iteration_parameter__ - the scraper' iteration parameter.
* __&block__ - An arbitrary block of ruby code, its return value will be used to determine the value of the next iteration's offset parameter.

## Running tests

ExtraLoop uses `rspec` and `rr` as its testing framework. The test suite can be run by calling the `rspec` executable from within the `spec` directory:

    cd spec
    rspec *
    
