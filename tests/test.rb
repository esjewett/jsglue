require 'rubygems'
gem 'jbarnette-johnson'
require 'johnson'

boundary = "TiDHew86xk"

class Req
  def test(s)
    s
  end
end

req = Req.new

rt = Johnson::Runtime.new
rt[:alert] = lambda { |x| puts x }
rt[:foo] = "Hello world"
rt[:req] = req

rt.evaluate('alert(foo)')
puts rt.evaluate('foo')
puts rt.evaluate('req.test( "This is a test" )')