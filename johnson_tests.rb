require 'rubygems'
require 'johnson'
require 'uri'
require 'net/http'

def create_new_request(request_type, url_string)
  u = URI.parse(url_string)
  
  req = case request_type
    when 'GET' then Net::HTTP::Get.new(u.path + '?' + u.query)
    when 'POST' then Net::HTTP::Post.new(u.path + '?' + u.query)
    when 'PUT' then Net::HTTP::Put.new(u.path + '?' + u.query)
    when 'DELETE' then Net::HTTP::Delete.new(u.path + '?' + u.query)
  end
end

ctx = Johnson::Runtime.new
ctx[:alert] = lambda { |x| puts x }
ctx.evaluate('alert("Hello world!");')

ctx[:URI] = URI
ctx.evaluate("var y = URI.parse('http://www.esjewett.com')")
puts ctx.evaluate('y').host
puts ctx.evaluate('y').port
puts ctx.evaluate('y').class

ctx[:create_new_request] = lambda { |type, url| create_new_request(type, url) }
ctx.evaluate("var req = create_new_request('POST', 'http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d');")
ctx.evaluate("req.set_content_type('multipart/form-data', { 'boundary' : 'TiDHew86xk' });")
#ctx.evaluate('req').set_content_type('multipart/form-data', {'boundary'=>'TiDHew86xk'})

puts ctx.evaluate('req').content_type

ctx.evaluate("var x = new (new Ruby.Struct(Johnson.symbolize('foo')));")
ctx.evaluate("x.foo = 'bar'")
puts ctx.evaluate('x').foo # => 'bar'
puts ctx.evaluate('x').class # => #<Class:0x49714>