require 'rubygems'
require 'json/pure'
require 'connector'
require 'spec'
require 'spec/interop/test'
require 'sinatra/test'

describe 'Processor maintenance app:' do
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
  
  it 'optionally stores a response script to customize the response' do
    post_body = Hash.new
    post_body[:path] = 'abcd'
    post_body[:script] = 'return "Hello World!";'
    post_body[:response_script] = 'return "Hello World!";'
    
    post '/processor', JSON.generate(post_body)
    
    processor = Processor.all.last
    processor.response_script.should == 'return "Hello World!";'
  end
    
end