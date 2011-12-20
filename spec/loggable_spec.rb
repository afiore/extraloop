require 'helpers/spec_helper'

class LoggableClass
  attr_reader :super_called
  include Loggable

  def initialize
    @super_called=true
  end
end

describe Loggable do
  describe "#initialize" do

    subject { LoggableClass.new }


    it "should execute the class' #initialize method" do
      subject.super_called.should eql(true)
    end


    it "should respond to the #log method" do
      subject.respond_to?(:log).should be_true
    end
  end
end
