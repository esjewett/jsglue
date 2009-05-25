require 'rubygems'
require 'spec'
require 'lib/runner'

describe "When it receives a sample request from Yahoo! Pipes for forwarding to Tarpipe" do
  before(:each) do
    Job.all.destroy!
    Processor.all.destroy!
    
    job = Job.new
    env = Hash.new
    env['PATH_INFO'] = '/abcd'
    env['BODY'] = <<-END
      data={
    		"items":[
    		  {
    		    "title": "First Title",
    		    "link": "http://example.com/first",
    		    "description": "First Description"
    		  },
    		  {
    		    "title": "Last Title",
    		    "link": "http://example.com/last",
    		    "description": "Last Description"
    		  }
    		]
    	}
      END
    job.environment = env
    job.save
    processor = Processor.new
    processor.path = '/abcd'
    processor.script = <<-END
        var reqs = [];
        var req_hash = {};
        var boundary = 'TiDHew86xk'
        var json_stuff = job_request_env['BODY'];
        eval(json_stuff);
        var body = data.items[0].description;
        var title = data.items[0].title;
        req_hash['url'] = URI.parse('http://api.tarpipe.net/1.0/?key=f9d8e2df8b7ba57a4dd7e490b60d961d');
        req_hash['request'] = NetHTTPPost.new(req_hash['url'].path + '?' +  req_hash['url'].query);
        set_request_content_type(req_hash['request'], 'multipart/form-data', {'boundary':boundary})
        var multi_part_body_json = {'title':title, 'body':body};
        set_request_body(req_hash['request'], encode_multi_part_form_data(boundary, multi_part_body_json));
        reqs[0] = req_hash;
        END
    processor.save
  end
  
  it 'processes the request and posts to Tarpipe endpoint' do
    Runner.new.process
  end
end