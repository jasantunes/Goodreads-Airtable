zip_file = deploy.zip
source_files = lambda_function.rb vendor author.rb book.rb genre.rb goodreads_client.rb importer.rb serie.rb
function_name = goodreads_airtable

deploy: package upload clean

package:
	bundle clean
	bundle install --path vendor/bundle
	zip -r $(zip_file) $(source_files)

upload:
	aws lambda update-function-code \
                --function-name $(function_name)  \
                --zip-file fileb://$(zip_file) \
                --publish

clean:
	rm $(zip_file)

test:
	aws lambda invoke-async \
	              --region us-west-2
								--function-name $(function_name)
								--invoke-args data.json
