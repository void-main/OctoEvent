require 'httpclient'
require 'json'
require_relative 'helper'

class OctoEvent
  GITHUB_EVENT_API_END_POINT = "https://api.github.com/%s/events"

  attr_accessor :config_url
  attr_accessor :parsing_block
  attr_accessor :target_array
  attr_accessor :client_id
  attr_accessor :client_secret
  attr_accessor :etag_hash
  attr_accessor :last_event_hash
  attr_accessor :sleep_period

  def initialize *args, &block
    @etag_hash = Hash.new ""         # a hash for etags
    @last_event_hash = Hash.new ""   # a hash for last event

    @sleep_period = 1

    case args.size
    when 1
      # Using a remote url to serve as the config json
      # Benefits? We can dynamiclly change it!
      # Also needs to pass in a block that does what it takes to trim the json
      @clnt = HTTPClient.new
      @config_url = args[0]
      @parsing_block = block
    when 3
      # For a single target who shell never change, just provide it with github login & type
      name, type, etag = args
      @config_url = nil
      path = path_for name, type
      target_array << path
      @etag_hash[path] = etag
    end
  end

  def github_key_pair client_id, client_secret
    @client_id = client_id
    @client_secret = client_secret
  end

  def to_s
    "Grab events for #{target_array}"
  end

  def target_array
    @target_array ||= []
  end

  def grab event_types, &block
    raise "nothing to do if there's no block" unless block

    acceptable_events = event_types.parse_event_types
    while true # this is a worker dyno
      update_target if @config_url

      result = {}
      target_array.each do |target|
        events = events_for target, acceptable_events
        result[target] = events unless events.empty?
      end

      block.call result unless result.empty? # send the result to client unless it's empty

      sleep sleep_period
    end
  end

  private
  # Composed path for github
  def path_for name, type
    "#{type}s/#{name}"
  end

  # Use json as config to make the users dynamiclly changable
  def update_target
    obj = JSON.load(@clnt.get(@config_url).body) || []
    obj = @parsing_block.call(obj) if @parsing_block

    obj.each do |target|
      name = target["name"]
      type = target["type"]
      target_array << "#{type}s/#{name}"
    end
  end

  # Get events for a single target
  def events_for target, event_types
    url = GITHUB_EVENT_API_END_POINT % target
    etag = @etag_hash[target]
    last_event = @last_event_hash[target]

    events_to_send = []
    page = 1
    while page <= 10
      result = @clnt.get(url, {client_id: @client_id, client_secret: @client_secret}, {"If-None-Match" => etag})
      break unless result.status_code == 200
      events = JSON.load result.body
      if page == 1 # etag and last event should be set when querying the very first page
        @etag_hash[target] = result.header["etag"]
        @last_event_hash[target] = events[0]
      end

      events.each do |event|
        return events_to_send if last_event == event # no need to proceed
        events_to_send << event if event_types.accept? event
      end

      page += 1
    end

    events_to_send
  end
end

# Create a new object
octo = OctoEvent.new "http://61.167.60.58:5984/octo-caddice/targets" do |raw|
  (raw.has_key? "list") ? raw["list"] : raw
end

# setup gh key pair for it
octo.github_key_pair ENV["GH_KEY_PAIR_ID"], ENV["GH_KEY_PAIR_SECRET"]

# And now it comes the events
octo.grab "all" do |events|
  puts events
end
