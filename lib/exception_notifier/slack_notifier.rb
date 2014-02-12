require 'action_dispatch'

module ExceptionNotifier
  class SlackNotifier

    def initialize(options)
      @team = options.delete(:team)
      @token = options.delete(:token)
      @default_options = options.reverse_merge(default_options)

      raise ArgumentError, "Team name required" if @team.nil?
      raise ArgumentError, "Token required" if @token.nil?
    end

    def call(exception, options={})
      options = options.reverse_merge(@default_options)
      
      subject = ""
      subject << "[#{Rails.env}] [#{Rails.application.class.parent_name}] " if defined?(Rails)

      data = options[:data] || {}
      
      backtrace = exception.backtrace ? clean_backtrace(exception) : []
      inflector = exception.class.to_s =~ /^[aeiou]/i ? 'An' : 'A'
      subject << "#{inflector} #{exception.class} occurred: '#{exception.message}'\n"
      
      options[:text] = subject
      options[:attachments] = [
        {
          :fallback => "Backtrace and message data",
          :color => "danger",
          :fields => [
            {
              :title => "Data:",
              :value => data.stringify_keys.to_yaml,
              :short => false
            },
            {
              :title => "Backtrace:",
              :value => backtrace.join("\n"),
              :short => false
            }
          ]
        }
      ]
      params = {:body => {:payload => options.to_json}}
      HTTParty.send(:post, url, params)
    end
    
    private
    
    def default_options
      {:username => 'Exception'}
    end

    def url
      "https://#{@team}.slack.com/services/hooks/incoming-webhook?token=#{@token}"
    end

    def clean_backtrace(exception)
      if defined?(Rails) && Rails.respond_to?(:backtrace_cleaner)
        Rails.backtrace_cleaner.send(:filter, exception.backtrace)
      else
        exception.backtrace
      end
    end

  end
end
