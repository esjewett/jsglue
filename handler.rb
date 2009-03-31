class Handler
  
  def initialize
    @stack = Array.new
  end
  
  def call(env)
    @stack << env
    
    [
      200,          # Status code
      {             # Response headers
        'Content-Type' => 'text/html'
      },
      [env.to_s]        # Response body
    ]
  end
  
end