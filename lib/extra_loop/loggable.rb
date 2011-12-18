autoload :Logging,  "logging"

module Loggable
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
  # Convenience method for logging messages
  #
  # messages  - the message content
  # log_level - the message's log level (can be either :info, :debug, :error, :warning; defaults to :info)
  #

  def log(message, log_level = :info)
    @log.send(log_level, message) if @log
  end
end


# Monkey patch ScraperBase to include the loggable module
# the its initialize method
#

class ScraperBase
  include Loggable
  alias_method :base_initialize, :initialize

  def initialize(*args)
    base_initialize(*args)
    init_log!
  end
end
