require 'test_helper'
require 'httparty'

class SlackNotifierTest < ActiveSupport::TestCase

  test "should not send slack notification if team name is missing" do
    wrong_params  = {:token => 'good_token'}

    exception = assert_raise(ArgumentError) { ExceptionNotifier::SlackNotifier.new(wrong_params) }
    assert_equal("Team name required", exception.message) 
  end

  test "should not send slack notification if token is missing" do
    wrong_params  = {:team => 'team1'}

    exception = assert_raise(ArgumentError) { ExceptionNotifier::SlackNotifier.new(wrong_params) }
    assert_equal("Token required", exception.message) 
  end

  test "should send slack notification if properly configured" do
    options = {
      :team => 'team1',
      :token => 'good_token'
    }
    
    expected_url = "https://team1.slack.com/services/hooks/incoming-webhook?token=good_token"
    expected_params = {
      :body => {
        :payload => {
          :username => "Exception",
          :text => "[test] [Dummy] A ZeroDivisionError occurred: 'divided by 0'\n",
          :attachments => [
            {
              :fallback => "Backtrace and message data",
              :color => "danger",
              :fields => [
                {
                  :title => "Data:",
                  :value => "--- {}\n",
                  :short => false
                },
                {
                  :title => "Backtrace:",
                  :value => "line1\nline2",
                  :short => false
                }
              ]
            }
          ]
        }.to_json
      }
    }

    HTTParty.expects(:send).with(:post, expected_url, expected_params)
    
    slack = ExceptionNotifier::SlackNotifier.new(options)
    slack.call(fake_exception)
  end

  test "should allow custom username if set" do
    options = {
      :team => 'team1',
      :token => 'good_token',
      :username => 'mr_roboto'
    }
    expected_url = "https://team1.slack.com/services/hooks/incoming-webhook?token=good_token"
    expected_params = {
      :body => {
        :payload => {
          :username => "mr_roboto",
          :text => "[test] [Dummy] A ZeroDivisionError occurred: 'divided by 0'\n",
          :attachments => [
            {
              :fallback => "Backtrace and message data",
              :color => "danger",
              :fields => [
                {
                  :title => "Data:",
                  :value => "--- {}\n",
                  :short => false
                },
                {
                  :title => "Backtrace:",
                  :value => "line1\nline2",
                  :short => false
                }
              ]
            }
          ]
        }.to_json
      }
    }

    HTTParty.expects(:send).with(:post, expected_url, expected_params)

    slack = ExceptionNotifier::SlackNotifier.new(options)
    slack.call(fake_exception)
  end

  test "should allow custom channel if set" do
    options = {
      :team => 'team1',
      :token => 'good_token',
      :channel => 'the_weather_channel'
    }
    expected_url = "https://team1.slack.com/services/hooks/incoming-webhook?token=good_token"
    expected_params = {
      :body => {
        :payload => {
          :username => "Exception",
          :channel => "the_weather_channel",
          :text => "[test] [Dummy] A ZeroDivisionError occurred: 'divided by 0'\n",
          :attachments => [
            {
              :fallback => "Backtrace and message data",
              :color => "danger",
              :fields => [
                {
                  :title => "Data:",
                  :value => "--- {}\n",
                  :short => false
                },
                {
                  :title => "Backtrace:",
                  :value => "line1\nline2",
                  :short => false
                }
              ]
            }
          ]
        }.to_json
      }
    }
    HTTParty.expects(:send).with(:post, expected_url, expected_params)

    slack = ExceptionNotifier::SlackNotifier.new(options)
    slack.call(fake_exception)
  end

  test "should allow optional params to be overridden" do
    options = {
      :team => 'team1',
      :token => 'good_token',
      :username => 'mr_roboto',
      :channel => 'the_weather_channel'
    }
    expected_url = "https://team1.slack.com/services/hooks/incoming-webhook?token=good_token"
    expected_params = {
      :body => {
        :payload => {
          :username => "mr_potato_head",
          :channel => "nickelodeon",
          :text => "[test] [Dummy] A ZeroDivisionError occurred: 'divided by 0'\n",
          :attachments => [
            {
              :fallback => "Backtrace and message data",
              :color => "danger",
              :fields => [
                {
                  :title => "Data:",
                  :value => "--- {}\n",
                  :short => false
                },
                {
                  :title => "Backtrace:",
                  :value => "line1\nline2",
                  :short => false
                }
              ]
            }
          ]
        }.to_json
      }
    }
    HTTParty.expects(:send).with(:post, expected_url, expected_params)

    slack = ExceptionNotifier::SlackNotifier.new(options)
    slack.call(fake_exception, {:username => 'mr_potato_head', :channel => 'nickelodeon'})
  end

  private

  def fake_exception
    exception = begin
      5/0
    rescue Exception => e
      e.set_backtrace(["line1", "line2"])
      e
    end
  end
end
