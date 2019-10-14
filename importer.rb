require 'logger'
require 'goodreads'
require 'airrecord'
require_relative 'goodreads_client'
require_relative 'book'

Airrecord.api_key = ENV['AIRTABLE_KEY']
FORCE_UPDATE = ENV['FORCE_UPDATE'] == 'true'

class Importer
  USER_ID = ENV['GOODREADS_ID'].to_i
  SHELVES = %w[read to-read currently-reading].freeze
  READ    = 'read'.freeze

  class << self
    def import_from_goodreads
      existing_books = Book.all
      SHELVES.each do |shelf_name|
        logger.info("Starting shelf: #{shelf_name}")
        shelf = get_shelf(shelf_name)
        mark_read = shelf_name == READ
        import_from_shelf(shelf, existing_books, mark_read, FORCE_UPDATE)
      end
    end

    def import_from_shelf(shelf, existing_books, mark_read, force_update = false)
      books = shelf.books
      books_length = books.length
      books.each_with_index do |shelf_book, idx|
        book = shelf_book.book
        my_rating = shelf_book.rating.to_i
        logger.info("#{idx + 1}/#{books_length} - #{book.title}")

        existing_book = find_existing_book(existing_books, book)
        need_to_update = force_update || existing_book.nil? || existing_book&.need_to_update?(mark_read, my_rating)
        logger.info('skipped') unless need_to_update
        next unless need_to_update

        existing_book ||= Book.new('Title' => book.title)
        existing_book.update(book, mark_read, my_rating)
        message = 'updated'
        message += ' (forced)' if force_update
        logger.info(message)
      end
    end

    def find_existing_book(existing_books, book)
      existing_books.find { |other| other.equals_to(book) }
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def get_shelf(shelf_name)
      options = { 'per_page' => 200 }
      page = 0
      last = 0
      total = nil
      books = []
      while total.nil? || last < total
        res = GoodreadsClient::Client.shelf(USER_ID, shelf_name, options.merge({ 'page' => page }))
        last = res['end']
        total = res['total'] if total.nil?
        books += res['books']
        page += 1
      end

      Hashie::Mash.new(start: 0, end: last, total: total, books: books)
    end
  end
end
