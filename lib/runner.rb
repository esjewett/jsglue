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
  #
  # Javascript processor has access to the following helper classes from the Ruby standard library:
  #   URI - URI class
  #   NetHTTP - Net::HTTP class
  #   NetHTTPGet - Net::HTTP::Get class (also NetHTTPPost, NetHTTPPut, and NetHTTPDelete for corresponding classes)
  #
  # The following variables are provided:
  #   job_request_env - the complete environment passed from the original request, as a Hash (Rack format), 
  #                     with input stream converted to a string and stored with hash key 'BODY'.
  #
  # And the following helper functions:
  #   encode_multipartformdata(boundary, body) - takes a 'boundary' string and a 'body' hash with values to be
  #                                              concatenated in multi-part format.
  #   set_request_body(request, body) - calls the .body= method of the 'request' passed in with 'body' as the value
  #   set_request_content_type(request, content_type, content_type_options) - facade of NetHTTPGenericRequest.set_content_type
  
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
            Net::HTTP.new(req_hash['url'].host, req_hash['url'].port).start {|http|
              http.request(req_hash['request'])
            }
          end 
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