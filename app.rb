# frozen_string_literal: true

require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
  raise 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

realtime_client = Slack::RealTime::Client.new
web_client = Slack::Web::Client.new
web_client.auth_test

realtime_client.on :hello do
  puts "Successfully connected, welcome '#{realtime_client.self.name}' to the '#{realtime_client.team.name}' team at https://#{realtime_client.team.domain}.slack.com."
end

# realtime_client.on :reaction_added do |data|
#   web_client.chat_postMessage(channel: '#times_hosoya', text: ":#{data.reaction}:", as_user: true)
# end

realtime_client.on :reaction_removed do |data|
  user_info = web_client.users_info(user: data.user)
  message = "#{user_info.user.name} が :#{data.reaction}: のリアクションを消したよ"
  web_client.chat_postMessage(channel: '#times_hosoya', text: message, as_user: true)
end

realtime_client.on :emoji_changed do |data|
  break unless data.subtype == 'add'
  web_client.chat_postMessage(channel: '#times_hosoya', text: ":#{data.name}: が追加されたよ。使っていこう！", as_user: true)
end

realtime_client.start!
