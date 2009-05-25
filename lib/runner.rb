require 'dm-core'
require 'dm-aggregates'
require 'johnson'
require 'net/http'
require 'lib/job'
require 'lib/processor'

DataMapper.setup(:default, 'sqlite3::connector_db')

class Runner
  
  # Expect javascript processor to return an array 'reqs' of hashes of the form:
  # {'request' => ?, 'url' => ?}
  # where the value of 'request' inherits from a Net::HTTP::GenericRequest object,
  # and the value of 'url' is the URL to which the request is sent.
  
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

          # Helpers
          request_processor[:encode_multi_part_form_data] = lambda { |boundary, body| encode_multipartformdata(boundary, body) }
          request_processor[:set_request_body] = lambda { |request, body| set_request_body(request, body) }
          request_processor[:set_request_content_type] = lambda { |request, content_type, content_type_options| set_request_content_type(request, content_type, content_type_options) }

          request_processor.evaluate(processor.script)
          
          request_processor.evaluate('reqs').each do |req_hash|
            #req_hash['request'].set_content_type(req_hash['content_type'], req_hash['content_type_options'])
            Net::HTTP.new(req_hash['url'].host, req_hash['url'].port).start {|http|
              http.request(req_hash['request'])
            }
          end 

          #request_processor.evaluate('req').set_content_type(request_processor.evaluate('content_type'), request_processor.evaluate('content_type_options'))
          #request_processor.evaluate('req').body = request_processor.evaluate('body')
          
          #res = Net::HTTP.new(request_processor.evaluate('url').host, request_processor.evaluate('url').port).start {|http| http.request(request_processor.evaluate('req')) }
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
  
  def set_request_body(request, body)
    request.body = body
  end
  
  def set_request_content_type(request, content_type, content_type_options)
    request.set_content_type(content_type, content_type_options)
  end
end