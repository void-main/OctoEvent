# Helper methods

# Mixin helper to parse the accpetable strings
class String
  def parse_event_types
    self.split(",").map {|str| "#{str.strip.capitalize}Event"}
  end
end

# Mixin helper to test if we should accept this event
class Array
  def accept? event
    return true if self.include? "AllEvent"
    return false unless event.has_key? "type"
    self.include? event["type"]
  end
end
