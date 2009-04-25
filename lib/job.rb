class Job
  include DataMapper::Resource
  
  property :id,             Integer, :serial => true
  property :environment,    Object
  
end