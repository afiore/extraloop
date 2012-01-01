autoload :Logging,  "logging"

module ExtraLoop
  # Decorates a class with an instance of Logging.logger and a convenient 
  # helper method to log messages.

  module Loggable
    protected

    #
    # Initializes the incorporated logger object.
    #
    # Returns nothing.
    #

    def init_log!
      return unless @options[:log]

      @options[:log] ||= {
        :appenders => [ Logging.appenders.stderr ],
        :log_level => :info
      }

      if @options[:log] && @options[:log][:appenders] && @options[:log][:appenders].any?
        @log = Logging.logger["#{self}"]
        @log.add_appenders(@options[:log][:appenders])
        @log.level = @options[:log] && @options[:log][:log_level] || :info
      end
    end

    # 
    # Convenience method for logging messages.
    #
    # messages  - the message content
    # log_level - the message's log level (can be either :info, :debug, :error, :warning; defaults to :info)
    #
    # Returns nothing.
    #

    def log(message, log_level = :info)
      @log.send(log_level, message) if @log
    end
  end

  # 
  #  Monkey patches ScraperBase.
  #
  class ScraperBase
    include Loggable
    alias_method :base_initialize, :initialize

    #
    # Wrapp ScraperBase#initialize method into Loggable#initialize
    #
    # args - The arguments to be passed over to the ScraperBase#initialize method.
    #
    # Returns itself.
    #
    def initialize(*args)
      base_initialize(*args)
      init_log!
      self
    end
  end
end
