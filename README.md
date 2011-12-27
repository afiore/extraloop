# Extra Loop

A Ruby library for extracting structured datasets from websites and web based APIs. 
Supports most common document formats (i.e. HTML, XML, and JSON), and comes with a handy mechanism 
for iterating over paginated datasets.


### Installation:

    `gem install extraloop`

### Usage examples:

A Scraper that fetches URL, title, and publisher from some 110 Google News articles mentioning the keyword 'Egypt'.

    results = []

    IterativeScraper.
       new("https://www.google.com/search?tbm=nws&q=Egypt").
       set_iteration(:start, (1..101).step(10)).
       loop_on("h3", proc { |nodes| nodes.map(&:parent) }).
         extract(:title, "h3.r a").
         extract(:url, "h3.r a", :href).
         extract(:source, "br", proc { |node| node.next.text.split("-").first }).
       set_hook(:on_data, proc { |data, response| data.each { |record| results << record } }).
       run()


### Initialization:

    `#new(urls, scraper_options, httpclient_options )`

- `urls` - single or array of urls.
- `scraper_options` - hash of scraper options (see below).
- `httpclient_options` - hash of request options for `Typheous::Request.new` (see rdocs for details).

#### Scraper options:
* `async` - Specifies whether the scraper's HTTP requests should be run in parallel or in series (defaults to false). **Note:** _currently only GET requests can be run asynchronously_.
* `log` - Logging options hash:
     * `loglevel`  - a symbol specifying the desired log level (defaults to `:info`).
     * `appenders` - a list of Logging.appenders object (defaults to `Logging.appenders.sterr`).


### Extractors:



### Iteration methods:

The `IterativeScraper` class comes with two methods for defining how a scraper should loop over paginated content. 


`#set_iteration(iteration_parameter, array_range_or_proc)`

* `iteration_parameter` - A symbol identifying the request parameter that the scraper will use as offset in order to iterate over the paginated content.
* `array_or_range_or_proc` - Either an explicit set of values or a block of code. If provided, the block is called with the parsed document as its first argument. Its return value is then used to shift, at each iteration, the value of the iteration parameter. If the block fails to return a non empty array, the iteration stops.

The second iteration methods, `#continue_with`, allows to continue iterating untill an arbitrary block of code returns a positive, non-nil value.

`#continue_with(iteration_parameter, block)`

* `iteration_parameter` - the scraper' iteration parameter.
* `block` - An arbitrary block of ruby code, its return value will be used to determine the value of the next iteration's offset parameter.

