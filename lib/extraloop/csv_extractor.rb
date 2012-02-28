class ExtraLoop::CsvExtractor < ExtraLoop::ExtractorBase

  def initialize(*args)
    super(*args)
    @selector = args[2] if args[2] && args[2].is_a?(Integer)
  end

  def extract_field(row, record=nil)
    target = row = row.respond_to?(:entries)? row : parse(row)
    headers = @environment.document.first
    selector = !@selector && @field_name || @selector

    # allow using CSV column names or array indices as selectors
    target = row[headers.index(selector.to_s)] if selector && selector.to_s.match(/[a-z]/i)
    target = row[selector] if selector.is_a?(Integer)

    target = @environment.run(target, record, &@callback) if @callback
    target
  end

  def extract_list(input)
    rows = (input.respond_to?(:entries) ? input : parse(input))
    Array(@callback && @environment.run(rows, &@callback) || rows)
  end


  def parse(input, options=Hash.new)
    super(input)
    document = CSV.parse(input, options)
    @environment.document = document
  end
end
