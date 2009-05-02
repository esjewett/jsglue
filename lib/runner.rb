require 'dm-core'
require 'dm-aggregates'
require 'johnson'
require 'net/http'
require 'lib/job'
require 'lib/processor'

DataMapper.setup(:default, 'sqlite3::connector_db')

class Runner
  
  def process
    job = Job.first
    
    # A job exists (otherwise return false)
    if job
      
      processor = Processor.first(:path => job.environment['PATH_INFO'])
      
      # A processor exists for the job (otherwise trash the job)
      if processor
        
        # If this doesn't work, we still need to get rid of the job (we comment for now so that error bubble up)
        #begin
          # Set up our objects
          request_url_host = String.new
          request_url_port = String.new
          request_method = String.new
        
          request_processor = Johnson::Runtime.new
          request_processor.evaluate("Ruby = null;") # Sandbox it.
          
          boundary = 'TiDHew86xk'
          req = create_new_request('POST', 'http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d')
          req.body = encode_multipartformdata(boundary, {'title'=>'Test title', 'body'=>'Test body'})

          request_processor[:request_method] = request_method
          request_processor[:body] = lambda { |x| req.body = x }
          request_processor[:encode_multipartformdata] = lambda { |b, p| encode_multipartformdata(b, p) }
          request_processor[:set_content_type] = lambda { |x| req.set_content_type(x) }
          request_processor[:parse_url_host] = lambda { |x| URI.parse(x).host }
          request_processor[:parse_url_port] = lambda { |x| URI.parse(x).port }
          request_processor[:request_url_host] = request_url_host
          request_processor[:request_url_port] = request_url_port
          request_processor[:create_new_request] = lambda { |type, url| create_new_request(type, url) }
          request_processor.evaluate("set_content_type('multipart/form-data; boundary=TiDHew86xk');")
#          request_processor.evaluate("var form_data = {}")
#          request_processor.evaluate("form_data['title'] = 'Test title';")
#          request_processor.evaluate("form_data['body'] = 'Test body';")
#          request_processor.evaluate("body = encode_multipartformdata('TiDHew86xk', form_data);")
#          request_processor.evaluate("request_url_host = parse_url_host('http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d');")
#          request_processor.evaluate("request_url_port = parse_url_port('http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d');")

          request_url_host = URI.parse('http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d').host
          request_url_port = URI.parse('http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d').port

          res = Net::HTTP.new(request_url_host, request_url_port).start {|http| http.request(req) }
        #end
      end
      
      job.destroy
      
      return true
    else
      return false
    end
  end
  
  private
  
  def create_new_request(request_type, url)
    url = URI.parse('http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d')
    
    req = case request_type
      when 'GET' then Net::HTTP::Get.new(url.path + '?' + url.query)
      when 'POST' then Net::HTTP::Post.new(url.path + '?' + url.query)
      when 'PUT' then Net::HTTP::Put.new(url.path + '?' + url.query)
      when 'DELETE' then Net::HTTP::Delete.new(url.path + '?' + url.query)
    end
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
end