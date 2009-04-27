require 'rubygems'
require 'connector'
require 'spec'
require 'spec/interop/test'
require 'sinatra/test'

DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate!  

set :environment, :test

describe 'Connector input app:' do
  include Sinatra::Test
  
  before(:each) do
    Job.all.destroy!
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
      processor.script = 'return "Hello World!";'
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
  end
end