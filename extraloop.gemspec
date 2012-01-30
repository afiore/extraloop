Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.8.10'

  s.name              = 'extraloop'
  s.version           = '0.0.6'
  s.date              = '2012-01-30'
  s.rubyforge_project = 'extraloop'

  s.summary     = "A toolkit for online data extraction."
  s.description = "A Ruby library for extracting data from websites and web based APIs. Supports most common document formats (i.e. HTML, XML, and JSON), and comes with a handy mechanism  for iterating over paginated datasets."

  s.authors  = ["Andrea Fiore"]
  s.email    = 'andrea.giulio.fiore@googlemail.com'
  s.homepage = 'http://github.com/afiore/extraloop'

  s.require_paths = %w[lib]
  s.executables = []

  s.rdoc_options = ["--charset=UTF-8"]

  s.add_runtime_dependency('yajl-ruby', "~> 1.1.0")
  s.add_runtime_dependency('nokogiri', "~> 1.5.0")
  s.add_runtime_dependency('typhoeus', "~> 0.3.2")
  s.add_runtime_dependency('logging', "~> 0.6.1")

  s.add_development_dependency('rspec', "~> 2.7.0")
  s.add_development_dependency('rr', "~> 1.0.4")
  s.add_development_dependency('pry', "~> 0.9.7.4")
  
  # = MANIFEST =
  s.files = %w[
    History.txt
    README.md
  ] + (`git ls-files examples lib spec`).split("\n")
  # = MANIFEST =
end
