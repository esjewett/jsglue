require 'net/http'
require 'uri'

class Handler
  
  def initialize
  end
  
  def call(env)
    
    boundary = "TiDHew86xk"
    
    url = URI.parse(extract_target_url_from_query_string(env))
    req = Net::HTTP::Post.new(url.path + '?' + url.query)
    req.body = encode_multipartformdata(boundary, {'title'=>'Test title', 'body'=>'Test body'})
    req.set_content_type('multipart/form-data; boundary=' + boundary)
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    
    [
      200,          # Status code
      {             # Response headers
        'Content-Type' => 'text/html'
      },
      [res.body]       # Response body 
    ]
  end
  
  def encode_multipartformdata(boundary, parameters = {})
    ret = String.new
    parameters.each do |key, value|
      unless value.empty?
        ret << "\r\n--" << boundary << "\r\n"
        ret << "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n"
        ret << value
      end
    end
    ret << "\r\n--" << boundary << "--\r\n"
  end 
  
  def extract_target_url_from_query_string(e)
    t = e['QUERY_STRING'].to_s.slice(/url=[^&]*&?/)
    t.chomp!('&')
    t.reverse!.chomp!('=lru').reverse!
  end
  
end