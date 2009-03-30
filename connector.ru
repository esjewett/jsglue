class Handler
  def call(env)
    [
      200,          # Status code
      {             # Response headers
        'Content-Type' => 'text/html'
      },
      ['hello']        # Response body
    ]
  end
end

connector = Handler.new

run connector