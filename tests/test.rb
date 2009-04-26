require 'rubygems'
require 'connector'
require 'spec'
require 'spec/interop/test'
require 'sinatra/test'
require 'json/pure'

DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate!  

set :environment, :test

describe 'Connector input app:' do
  include Sinatra::Test
  
  before(:each) do
    Job.all.destroy!
  end
  
  describe 'when a processor for the path does not exist' do
    it 'returns "Invalid path"' do
      get '/abcd'
      response.should_not be_ok
      response.body.should == 'Invalid path.'
    end
  end
  
  describe 'when a processor for the path exists' do
    before(:each) do
      processor = Processor.new
      processor.path = 'abcd'
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
    
      get '/abdc?test=query_test'
      response.should be_ok
    
      job = Job.all.pop
    
      job.environment['QUERY_STRING'].should == 'test=query_test'
      job.environment.class.should == Hash
    end
  end
end

describe 'Processor maintenance app' do
  include Sinatra::Test
  
  before(:each) do
    Processor.all.destroy!
  end
  
  it 'returns the processor by id from /processor/:id' do
    processor = Processor.new
    processor.script = 'return "Hello World!";'
    processor.path = '/tata'
    processor.save
    
    get "/processor/" + processor.id.to_s
    response.should be_ok
    
    response.body.should == processor.to_s
  end
  
  it 'adds a new processor when it receives a post to /processor if in JSON format' do
    post_body = Hash.new
    post_body[:path] = 'abcd'
    post_body[:script] = 'return "Hello World!";'

    initial_length = Processor.all.length
    
    post '/processor', JSON.generate(post_body)
    response.should be_ok
    
    initial_length.should < Processor.all.length
  end
  
  it 'gives an error if a post goes to /processor and is not in JSON format' do
    post '/processor'
    response.should_not be_ok
    response.body.should == 'Invalid JSON'
  end
  
  it 'stores a script and path posted to /processor as json' do
    post_body = Hash.new
    post_body[:path] = 'abcd'
    post_body[:script] = 'return "Hello World!";'
    
    post '/processor', JSON.generate(post_body)
    
    processor = Processor.all.last
    processor.path.should == 'abcd'
    processor.script.should == 'return "Hello World!";'
  end
end