require 'rubygems'
require 'connector'
require 'spec'
require 'spec/interop/test'
require 'sinatra/test'

set :environment, :test

describe 'Connector input app:' do
  include Sinatra::Test
  
  before(:each) do
    Job.all.destroy!
    Processor.all.destroy!
  end
  
  describe 'a processor for the path does not exist' do
    it 'returns "Invalid path"' do
      get '/abcd'
      response.should_not be_ok
      response.body.should == 'Invalid path.'
    end
  end
  
  describe 'a processor for the path exists' do
    before(:each) do
      processor = Processor.new
      processor.path = '/abcd'
      processor.script = 'return "Hello world!";'
      processor.save
    end
    
    it 'returns "Request successful"' do
      get '/abcd'
      response.should be_ok
      response.body.should == "Request successful"
    end
  
    it 'adds a job to the stack' do
      initial_length = Job.all.length
    
      get '/abcd'
      response.should be_ok
    
      initial_length.should < Job.all.length
    end
  
    it 'stores the environment on the stack properly' do
    
      # We'll test that query parameters get passed in correctly
    
      get '/abcd?test=query_test'
      response.should be_ok
    
      job = Job.all.pop
    
      job.environment['QUERY_STRING'].should == 'test=query_test'
      job.environment.class.should == Hash
    end
  end
    
  describe 'a process for the path exists with a response script' do
    before(:each) do
      processor = Processor.new
      processor.path = '/abcd'
      processor.script = 'return "Hello World!";'
      processor.response_script = "response_body('Hello World!');"
      processor.save
    end
    
    it 'returns the response body defined in the script' do
      get '/abcd'
      
      response.should be_ok
      response.body.should == 'Hello World!'
    end
    
    it 'does not provide access to the Ruby object in the javascript context' do
      processor = Processor.first()
      processor.response_script = "if( !Ruby ){ response_body('A-okay'); }else{ response_body('Houston, we have a Ruby');}"
      processor.save
      
      get '/abcd'
      
      response.should be_ok
      response.body.should == 'A-okay'
    end
    
    it 'returns 200 with an explanation if there is a problem with the response script' do
      processor = Processor.first()
      processor.response_script = "this code is not valid javascript!!!"
      processor.save
      
      get '/abcd'
      
      response.should be_ok
      response.body.should == 'The request was registered successfully, but there was a little disagreement building your response. Sorry!'
    end
  end
end