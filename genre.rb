class Genre < Airrecord::Table
  self.base_key = ENV['AIRTABLE_BASE_ID']
  self.table_name = 'Genres'
end
