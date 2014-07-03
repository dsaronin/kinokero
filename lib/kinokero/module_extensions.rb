# Extends the module object with module and instance accessors for class attributes,
# just like the native attr* accessors for instance attributes.
#
#  module AppConfiguration
#    mattr_accessor :google_api_key
#    self.google_api_key = "123456789"
#
#    mattr_accessor :paypal_url
#    self.paypal_url = "www.sandbox.paypal.com"
#  end
#
#  AppConfiguration.google_api_key = "overriding the api key!"
#
# borrowed from Rails
#
class Module
  def mattr_reader(*syms)
    syms.each do |sym|

      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        @@#{sym} = nil unless defined? @@#{sym}

        def self.#{sym}
          @@#{sym}
        end
      EOS

    end  # do each
  end

  def mattr_writer(*syms)
    syms.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def self.#{sym}=(obj)
          @@#{sym} = obj
        end
      EOS

    end  # do each
  end

  def mattr_accessor(*syms)
    mattr_reader(*syms)
    mattr_writer(*syms)
  end

end  # class Module
