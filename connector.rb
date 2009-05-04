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
