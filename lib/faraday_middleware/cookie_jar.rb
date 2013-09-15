class CookieJar < Hash
  def to_s
    self.map { |key, value| "#{key}=#{value}"}.join("; ")
  end

  def parse(cookie_strings)
    cookie_strings.each { |s|
      key, value = s.split('; ').first.split('=', 2)
      self[key] = value
    }
    self
  end
end

# Use like this:
#  response = Typhoeus::Request.get("http://www.example.com")
#  cookies = CookieJar.new.parse(response.headers_hash["Set-Cookie"])
#  Typhoeus::Request.get("http://www.example.com", headers: {Cookie: cookies.to_s})
#
#  source: http://stackoverflow.com/questions/9810150/manually-login-into-website-with-typheous
#  author: http://stackoverflow.com/users/362378/igel
