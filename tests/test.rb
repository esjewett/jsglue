require 'rubygems'
require 'connector'
require 'spec'
require 'spec/interop/test'
require 'sinatra/test'

DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate!  

set :environment, :test

describe 'Connector input app' do
  include Sinatra::Test
  
  before(:each) do
    Job.all.destroy!
  end
  
  it 'returns "Request successful" upon "/method/abcd" call' do
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

describe 'Job stack behavior' do
  
  
  
end