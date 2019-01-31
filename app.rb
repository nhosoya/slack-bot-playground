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
emoji_channel = ENV.fetch('EMOJI_CHANNEL') # channel ID or name
channel_notification_channel = ENV.fetch('CHANNEL_NOTIFICATION_CHANNEL') # channel ID or name

realtime_client.on :hello do
  puts "Successfully connected, welcome '#{realtime_client.self.name}' to the '#{realtime_client.team.name}' team at https://#{realtime_client.team.domain}.slack.com."
end

# realtime_client.on :reaction_added do |data|
#   web_client.chat_postMessage(channel: data.item.channel, text: ":#{data.reaction}:", as_user: true)
# end

realtime_client.on :reaction_removed do |data|
  user_info = web_client.users_info(user: data.user)
  message = "#{user_info.user.name} が :#{data.reaction}: のリアクションを消したよ"
  puts message
  # web_client.chat_postMessage(channel: data.item.channel, text: message, as_user: true)
  web_client.reactions_add(name: data.reaction, channel: data.item.channel, timestamp: data.item.ts)
end

realtime_client.on :emoji_changed do |data|
  break unless data.subtype == 'add'
  web_client.chat_postMessage(channel: emoji_channel, text: ":#{data.name}: が追加されたよ。使っていこう！", as_user: true)
end

realtime_client.on :channel_created do |data|
  user_info = web_client.users_info(user: data.channel.creator)
  message = "#{user_info.user.name} が ##{data.channel.name} を作ったよ。そーっとのぞいてみよう！"
  web_client.chat_postMessage(channel: channel_notification_channel, text: message, as_user: true)
end

realtime_client.start!
