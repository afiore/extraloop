module ExtraLoop
  module Hookable

    module Exceptions
      class HookArgumentError < StandardError
      end
    end

    def set_hook(hookname, &handler)
      @hooks ||= {}
      @hooks[hookname.to_sym] ? @hooks[hookname.to_sym].push(handler) : @hooks[hookname.to_sym] = [handler]
      self
    end

    def run_hook(hook, arguments)
      return unless @hooks.has_key?(hook)

      @hooks[hook].each do |handler|
        (@environment || ExtractionEnvironment.new ).run(*arguments, &handler)
      end
    end

    alias_method :on, :set_hook
  end
end
