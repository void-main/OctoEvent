require 'httpclient'
require 'json'

class OctoEvent
  GITHUB_EVENT_API_END_POINT = "https://api.github.com/%s/events"
  A_WHILE = 1 # Sleep duration

  attr_accessor :config_url
  attr_accessor :parsing_block
  attr_accessor :target_array
  attr_accessor :etag_hash

  def initialize *args, &block
    @etag_hash = Hash.new "" # a hash for etags

    case args.size
    when 1
      # Using a remote url to serve as the config json
      # Benefits? We can dynamiclly change it!
      # Also needs to pass in a block that does what it takes to trim the json
      @clnt = HTTPClient.new
      @config_url = args[0]
      @parsing_block = block
    when 2
      # For a single target who shell never change, just provide it with github login & type
      name, type = args
      @config_url = nil
      target_array << path_for(name, type)
    end
  end

  def github_key_pair secret_id, secret_key
  end

  def to_s
    "Grab events for #{target_array}"
  end

  def target_array
    @target_array ||= []
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

  def grab event_types, &block
    raise "nothing to do if there's no block" unless block
  end

  private
  # Composed path for github
  def path_for name, type
    "#{type}s/#{name}"
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
