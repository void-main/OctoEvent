require 'octoevent'

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
