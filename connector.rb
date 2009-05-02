require 'rubygems'
require 'sinatra'
require 'johnson'
require 'dm-core'
require 'json/pure'
require 'lib/job'
require 'lib/processor'

DataMapper.setup(:default, 'sqlite3::connector_db')
DataMapper.auto_migrate!

get '/processor/:id' do
  Processor.all(:id => params[:id]).to_s
end

post '/processor' do
  begin
    processor_hash = JSON.parse(request.body.read)
    processor = Processor.new
    processor.path = processor_hash['path']
    processor.script = processor_hash['script']
    processor.response_script = processor_hash['response_script']
    processor.save
  rescue
    halt 400, 'Invalid JSON'
  end
end

get '/*' do
  if Processor.first(:path => env['PATH_INFO'])
    handle_request(env)
  else
    halt 400, 'Invalid path.'
  end
end

post '/*' do
  if Processor.first(:path => env['PATH_INFO'])
    handle_request(env)
  else
    halt 400, 'Invalid path.'
  end
end

error do
  "Sorry, there was an error: " + request.env['sinatra.error'].message
end

helpers do
  def handle_request(env)

    # Drop all "rack." keys from env Hash (drops StringIO types that don't marshal)
    env.delete_if { |k,v| k =~ /rack./}

    response_body = String.new
    
    # Store request on the stack to be processed.

    job = Job.new
    job.environment = env
    job.save

    begin  # Determine the response (optionally dynamic)
      processor = Processor.first(:path => env['PATH_INFO'])
    
      response_processor = Johnson::Runtime.new
      response_processor.evaluate("Ruby = null;") # Sandbox it.
      response_processor[:response_body] = lambda { |x| response_body = x }
      response_processor.evaluate(processor.response_script)

      response_body
    rescue
      response_body = 'The request was registered successfully, but there was a little disagreement building your response. Sorry!'
    end
  end
end


#request_processor = Johnson::Runtime.new

#req = create_new_request(env['REQUEST_METHOD'], 'http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d')

#req.body = encode_multipartformdata(boundary, {'title'=>'Test title', 'body'=>'Test body'})

#request_processor[:request_method] = request_method
#request_processor[:body] = lambda { |x| req.body = x }
#request_processor[:encode_multipartformdata] = lambda { |b, p[]| encode_multipartformdata(b, p) }
#request_processor[:set_content_type] = lambda { |x| req.set_content_type(x) }
#request_processor[:parse_url] = lambda { |x| URI.parse(x) }
#request_processor[:request_url] = request_url
#request_processor[:create_new_request] = lambda { |type, url| create_new_request(type, url) }
#request_processor.evaluate("set_content_type('multipart/form-data; boundary=TiDHew86xk');")
#request_processor.evaluate("url = parse_url('http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d')")
#request_processor.evaluate("request_url = url")

#res = Net::HTTP.new(request_url.host, request_url.port).start {|http| http.request(req) }


#def encode_multipartformdata(boundary, parameters = {})
#  ret = String.new
#  parameters.each do |key, value|
#    unless value.empty?
#      ret << "\r\n--" << boundary << "\r\n"
#      ret << "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n"
#      ret << value
#    end
#  end
#  ret << "\r\n--" << boundary << "--\r\n"
#end

#def create_new_request(request_type, url)
#  url = URI.parse('http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d')
#  
#  req = case request_type
#    when 'GET' then Net::HTTP::Post.new(url.path + '?' + url.query)
#    when 'POST' then Net::HTTP::Post.new(url.path + '?' + url.query)
#    when 'PUT' then Net::HTTP::Put.new(url.path + '?' + url.query)
#    when 'DELETE' then Net::HTTP::Delete.new(url.path + '?' + url.query)
#  end
#end