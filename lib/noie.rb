module Rack
  class NoIE
    def initialize(app, options = {})
      @app = app
      @options = options
      @options[:redirect] ||= 'http://www.microsoft.com/windows/internet-explorer/default.aspx'
      @options[:minimum] ||= 7.0
    end

    def call(env)
      if enforce_noie?(env) && ie_found_in?(env)
        kick_it
      else
        @app.call(env)
      end
    end

    private
    def ie_found_in?(env)
      if env['HTTP_USER_AGENT']
        is_ie?(env['HTTP_USER_AGENT']) and ie_version(env['HTTP_USER_AGENT']) < @options[:minimum] and @options[:redirect] != env['PATH_INFO']
      end
    end

    def is_ie?(ua_string)
      # We need at least one digit to be able to get the version, hence the \d
      ua_string.match(/MSIE \d/) && !ua_string.match(/MS Web Services Client Protocol/) ? true : false
    end

    def ie_version(ua_string)
      ua_string.match(/MSIE (\S+)/)[1].to_f
    end

    def kick_it
      [301, {'Location' => @options[:redirect]}, ['User agent not permitted.']]
    end

    def enforce_noie?(env)
      request = Rack::Request.new(env)
      if @options[:only]
        match_rule?(request.path, @options[:only])
      elsif @options[:except]
        !match_rule?(request.path, @options[:except])
      else
        true
      end
    end

    # matches a path against a rule
    # Accepts a string path, a regex matcher or an array of these
    def match_rule?(path, options)
      rules = [options].flatten
      rules.any? do |pattern|
        if pattern.is_a?(Regexp)
          path =~ pattern
        else
          path[0, pattern.length] == pattern
        end
      end
    end
  end
end