require 'net/http'
require 'uri'

class Handler
  
  def initialize
    @boundary = "TiDHew86xk"
  end
  
  def call(env)
    
    @target = env['QUERY_STRING'].to_s.slice(/url=[^&]*&?/)
    @target.chomp!('&')
    @target.reverse!.chomp!('=lru').reverse!
                              
    url = URI.parse('http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d')
    req = Net::HTTP::Post.new(url.path + '?' + url.query)
    req.body = encode_multipartformdata({'title'=>'Test title', 'body'=>'Test body'})
    req.set_content_type('multipart/form-data; boundary=' + @boundary)
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    
    [
      200,          # Status code
      {             # Response headers
        'Content-Type' => 'text/html'
      },
      [URI.unescape(url.path + '?' + url.query) + '-' + res.body]       # Response body 
    ]
  end
  
  def encode_multipartformdata(parameters = {})
    ret = String.new
    parameters.each do |key, value|
      unless value.empty?
        ret << "\r\n--" << @boundary << "\r\n"
        ret << "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n"
        ret << value
      end
    end
    ret << "\r\n--" << @boundary << "--\r\n"
  end 
end