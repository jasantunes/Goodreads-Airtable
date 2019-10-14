class Author < Airrecord::Table
  self.base_key = ENV['AIRTABLE_BASE_ID']
  self.table_name = 'Authors'
end
