class Processor
  include DataMapper::Resource
  
  property :id,             Integer, :serial => true
  property :path,           String, :key => true
  property :script,         String

  def to_s
    string = 'id: ' + self.id.to_s + '/n'
    string += 'path: ' + self.path.to_s + '/n'
    string += 'script: ' + self.script.to_s
    string
  end
end