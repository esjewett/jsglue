require 'rubygems'
require 'spec'
require 'lib/runner'

describe 'Job runner class:' do
  before(:each) do
    Job.all.destroy!
    Processor.all.destroy!
  end
  
  it 'exists and has classname "Runner"' do
    runner = Runner.new
    runner.class.should == Runner
  end
  
  it 'has a "process" method that returns false when there are no jobs on the job stack' do
    runner = Runner.new
    runner.process.should == false
  end
  
  describe 'when there are jobs on the job stack, the process method' do
    before(:each) do
      job = Job.new
      job.save
    end
    
    it 'has a "returns true' do
      runner = Runner.new
      runner.process.should == true
    end

    it 'decrements the job stack' do
      jobs = Job.all.count
      Runner.new.process
      Job.all.count.should == jobs - 1
    end
  end
  
  describe 'when there are jobs on the job stack and there are corresponding processors' do
    before(:each) do
      job = Job.new
      env = Hash.new
      env['PATH_INFO'] = '/abcd'
      job.environment = env
      job.save
      processor = Processor.new
      processor.path = '/abcd'
      processor.script = <<-END
          var reqs = [];
          var req_hash = {};
          var boundary = 'TiDHew86xk'
          req_hash['url'] = URI.parse('http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d');
          req_hash['request'] = NetHTTPPost.new(req_hash['url'].path + '?' +  req_hash['url'].query);
          req_hash['content_type'] = 'multipart/form-data';
          req_hash['content_type_options'] = {'boundary':boundary};
          var multi_part_body_json = {'title':'Test title', 'body':'Test body'}
          req_hash['body'] = encode_multi_part_form_data(boundary, multi_part_body_json);
          reqs[0] = req_hash;
          END
      processor.save
      processor = Processor.new
      processor.path = '/abcdefg'
      processor.script = 'request_body("Goodbye world!");'
      processor.save
    end
    
    it 'looks up the corresponding processor and evaluates the javascript code' do
      Runner.new.process
    end 
  end
end