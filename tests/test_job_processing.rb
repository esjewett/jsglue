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
      processor.script = 'request_body("Hello world!");'
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