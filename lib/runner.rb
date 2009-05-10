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
        begin
          request_processor = Johnson::Runtime.new
          request_processor.evaluate("Ruby = null;") # Sandbox it.
          
          # Provide the full environment of the request to the processing logic. (It's a hash/json)
          request_processor[:job_request_env] = job.environment
          
          request_processor[:URI] = URI
          request_processor[:NetHTTP] = Net::HTTP
          request_processor[:NetHTTPGet] = Net::HTTP::Get
          request_processor[:NetHTTPPost] = Net::HTTP::Post
          request_processor[:NetHTTPPut] = Net::HTTP::Put
          request_processor[:NetHTTPDelete] = Net::HTTP::Delete

          request_processor[:encode_multi_part_form_data] = lambda { |boundary, body| encode_multipartformdata(boundary, body) }

          request_processor.evaluate(processor.script)

          request_processor.evaluate('req').set_content_type(request_processor.evaluate('content_type'), request_processor.evaluate('content_type_options'))
          request_processor.evaluate('req').body = request_processor.evaluate('body')
          
          res = Net::HTTP.new(request_processor.evaluate('url').host, request_processor.evaluate('url').port).start {|http| http.request(request_processor.evaluate('req')) }
        rescue
          # Do nothing - want to fail silently and continue in the event of bad javascript, at least for now.
        end
      end
      
      job.destroy
      
      return true
    else
      return false
    end
  end
  
  private
  
#  def create_new_request(request_type, url_string)
#    u = URI.parse(url_string)
#    
#    req = case request_type
#      when 'GET' then Net::HTTP::Get.new(u.path + '?' + u.query)
#      when 'POST' then Net::HTTP::Post.new(u.path + '?' + u.query)
#      when 'PUT' then Net::HTTP::Put.new(u.path + '?' + u.query)
#      when 'DELETE' then Net::HTTP::Delete.new(u.path + '?' + u.query)
#    end
#  end
  
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