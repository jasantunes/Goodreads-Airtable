class GoodreadsClient
  Client = Goodreads::Client.new(api_key: ENV['GOODREADS_KEY'], api_secret: ENV['GOODREADS_SECRET'])
end
