class ExtractionLoop

  module Exceptions
    class UnsupportedFormat < StandardError; end
  end

  attr_reader :records
  attr_accessor :extractors, :document, :hooks, :children, :parent, :format

  def initialize(loop_extractor, extractors=[], document=nil, hooks = {})
    @loop_extractor = loop_extractor
    @extractors = extractors
    @document = @loop_extractor.parse(document)
    @records = []
    @hooks = hooks
    @parent = nil
    @format = format
    self
  end

  def run
    run_hook(:before, @document)

    get_nodelist.each do |node|
      run_hook(:before_extract, node)
      @records << run_extractors(node)
      run_hook(:after_extract, node, records.last)
    end

    run_hook(:after, @records)
    self
  end


  private

  def run_hook(hook, *arguments)
    hook = hook.to_sym
    @hooks[hook].call(*arguments) if @hooks.has_key?(hook)
  end

  def get_nodelist
    @loop_extractor.extract_list(@document)
  end

  def run_extractors(node)
    record = OpenStruct.new(:extracted_at => Time.now.to_i)
    @extractors.each { |extractor| record.send("#{extractor.field_name.to_s}=", extractor.extract_field(node, record)) }
    record
  end

end
