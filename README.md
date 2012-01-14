# Extra Loop

A Ruby library for extracting data from websites and web based APIs. 
Supports most common document formats (i.e. HTML, XML, and JSON), and comes with a handy mechanism 
for iterating over paginated datasets.

### Installation:

    gem install extraloop

### Usage:

A basic scraper that fetches the top 25 websites from Alexa's daily top 100 list:

    results = nil

    ExtraLoop::ScraperBase.
      new("http://www.alexa.com/topsites").
      loop_on("li.site-listing").
        extract(:site_name, "h2").
        extract(:url, "h2 a").
        extract(:description, ".description").
      on(:data, proc { |data| results = data }).
      run()

An Iterative Scraper that fetches URL, title, and publisher from some 110 Google News articles mentioning the keyword 'Egypt'.

    results = []

    ExtraLoop::IterativeScraper.
       new("https://www.google.com/search?tbm=nws&q=Egypt").
       set_iteration(:start, (1..101).step(10)).
       loop_on("h3", proc { |nodes| nodes.map(&:parent) }).
         extract(:title, "h3.r a").
         extract(:url, "h3.r a", :href).
         extract(:source, "br", proc { |node| node.next.text.split("-").first }).
       on(:data, proc { |data, response| data.each { |record| results << record } }).
       run()


### Initializations

    #new(urls, scraper_options, httpclient_options)

- `urls` - single url, or array of several urls.
- `scraper_options` - hash of scraper options (see below).
- `httpclient_options` - hash of request options for `Typheous::Request#initialize` (see [API documentation](http://rubydoc.info/github/pauldix/typhoeus/master/Typhoeus/Request#initialize-instance_method) for details).

#### Scraper options:
* `format` - Specifies the scraped document format (valid values are :html, :xml, :json). 
* `async` - Specifies whether the scraper's HTTP requests should be run in parallel or in series (defaults to false). **Note:** currently only GET requests can be run asynchronously.
* `log` - Logging options hash:
     * `loglevel`  - a symbol specifying the desired log level (defaults to `:info`).
     * `appenders` - a list of Logging.appenders object (defaults to `Logging.appenders.sterr`).

### Extractors

ExtraLoop allows to fetch structured data from online documents by looping through a list of elements matching a given selector.
For each matched element, an arbitrary set of fields can be extracted. While the `loop_on` method sets up such loop, the `extract` 
method extracts a piece of information from an element (e.g. a story's title) and and stores it into a record's field.

    # using a CSS3 or an XPath selector
    loop_on('div.post')

    # using a proc as a selector

    loop_on(proc { |doc| doc.search('div.post') })

    # using both a selector and a proc (matched elements are passed in as the first argument of the proc )

    loop_on('div.post', proc { |posts| posts.reject { |post| post.attr(:class) == 'sticky' }})

Both the `loop_on` and the `extract` methods may be called with a selector, a proc or a combination of the two. By default, when parsing DOM documents, `extract` will call
`Nokogiri::XML::Node#text()`. Alternatively, `extract` also accepts an attribute name or a proc as a third argument, this will be evaluated in the context of the matching element. 

    # extract a story's title 
    extract(:title, 'h3')

    # extract a story's url
    extract(:url, "a.link-to-story", :href)

    # extract a description text, separating paragraphs with newlines 
    extract(:description, "div.description", proc { |node|
      node.css("p").map(&:text).join("\n") 
    })

#### Extracting from JSON Documents

While processing each HTTP response, ExtraLoop tries to automatically detect the scraped document format by looking at 
the `ContentType` header sent by the server (this value may be overriden by providing a `:format` key in the scraper's 
initialization options). When the format is JSON, the document is parsed using the `yajl` parser and converted into a hash. 
In this case, both the `loop_on` and the `extract` methods still behave as illustrated above, with the sole exception 
of the CSS3/XPath selector string, which is specific of DOM documents. 

When working with JSON data, you can just use a proc and return the document elements you want to loop on.

    # Fetch a portion of a document using a proc
    loop_on(proc { |data| data['query']['categorymembers'] })

Alternatively, the same loop can be defined by passing an array of keys pointing at a value located 
at several levels of depth down into the parsed document hash.

    # Fetch the same document portion above using a hash path
    loop_on(['query', 'categorymembers'])

When fetching fields from a portion of a JSON document, `extract` will use the
field name as a hash key if no key path or key string is provided.

    # current node:
    # 
    # {
    #  'from_user' => "johndoe", 
    #  'text' => 'bla bla bla',
    #  'from_user_id'..
    # }

    # >> extract(:from_user)
    # => "johndoe"


### Iteration methods:

The `IterativeScraper` class comes with two methods for defining how a scraper should loop over paginated content.

_set_iteration(iteration_parameter, array_range_or_proc)_

* `iteration_parameter` - A symbol identifying the request parameter that the scraper will use as offset in order to iterate over the paginated content.
* `array_or_range_or_proc` - Either an explicit set of values or a block of code. If provided, the block is called with the parsed document as its first argument. Its return value is then used to shift, at each iteration, the value of the iteration parameter. If the block fails to return a non empty array, the iteration stops.

The second iteration methods, `#continue_with`, allows to continue iterating untill an arbitrary block of code returns a positive, non-nil value.

_continue_with(iteration_parameter, block)_

* `iteration_parameter` - the scraper' iteration parameter.
* `block` - An arbitrary block of ruby code, its return value will be used to determine the value of the next iteration's offset parameter.

### Running tests

ExtraLoop uses `rspec` and `rr` as its testing framework. The test suite can be run by calling the `rspec` executable from within the `spec` directory:

    cd spec 
    rspec *
