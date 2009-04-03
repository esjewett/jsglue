require 'net/http'
require 'uri'
require 'johnson'

class Handler
  
  def initialize
  end
  
  def call(env)
    
    boundary = "TiDHew86xk"
    
    url = URI.parse(extract_target_url_from_query_string(env))
    
    req = case env['REQUEST_METHOD']
    when 'GET' then Net::HTTP::Post.new(url.path + '?' + url.query)
    when 'POST' then Net::HTTP::Post.new(url.path + '?' + url.query)
    when 'PUT' then Net::HTTP::Put.new(url.path + '?' + url.query)
    when 'DELETE' then Net::HTTP::Delete.new(url.path + '?' + url.query)
    end

    rt = Johnson::Runtime.new
    rt.evaluate('Ruby = null')
    
    req.body = encode_multipartformdata(boundary, {'title'=>'Test title', 'body'=>'Test body'})
    #req.set_content_type('multipart/form-data; boundary=' + boundary)

    rt[:req] = req
    rt.evaluate("req.set_content_type();")

    #res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    
    [
      200,          # Status code
      {             # Response headers
        'Content-Type' => 'text/html'
      },
      [Johnson.evaluate("4 + 4").to_s]       # Response body 
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