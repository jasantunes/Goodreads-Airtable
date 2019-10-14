load_paths = Dir["./vendor/bundle/ruby/2.5.0/gems/**/lib"]
$LOAD_PATH.unshift(*load_paths)

require 'json'
require_relative 'importer'

def lambda_handler(event:, context:)
  Importer.import_from_goodreads
  { statusCode: 200, body: JSON.generate('Hello from Lambda!') }
end

lambda_handler(event: nil, context: nil) if $PROGRAM_NAME == __FILE__
