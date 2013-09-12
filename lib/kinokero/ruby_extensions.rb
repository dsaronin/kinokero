# commonly used extensions from Rails for Ruby
#
  require 'kinokero/blank'

# ****************************************************************************
class Hash

# -----------------------------------------------------------------------------
# File activesupport/lib/active_support/core_ext/hash/keys.rb, line 48
# -----------------------------------------------------------------------------
  def assert_valid_keys(*valid_keys)
    valid_keys.flatten!
    each_key do |k|
      raise(ArgumentError, "Unknown key: #{k}") unless valid_keys.include?(k)
    end
  end
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

end  # class Hash
# ****************************************************************************
