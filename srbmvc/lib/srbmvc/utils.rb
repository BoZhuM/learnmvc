module Srbmvc
  def self.to_underscore(string)
    string.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

# class Object
#   def self.const_missing(c)
#     require Srbmvc.to_underscore(c.to_s)
#     Object.const_get(c)
#   end
# end
