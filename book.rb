require 'set'
require_relative 'author'
require_relative 'serie'
require_relative 'genre'
require_relative 'goodreads_client'

class Book < Airrecord::Table
  self.base_key = ENV['AIRTABLE_BASE_ID']
  self.table_name = 'Books'

  GOODREADS_BLACKLIST = %w[
    audiobook
    book-club
    books-i-own
    currently-reading
    ebook
    favorites
    favourites
    kindle
    owned
    owned-books
    re-read
    series
    si
    to-buy
    to-read
    wish-list
  ].freeze

  GOODREADS_MERGE = {
    'Auto-biography' => 'Memoir',
    'Autobiography' => 'Memoir',
    'Biographies' => 'Memoir',
    'Biography' => 'Memoir',
    'Classic' => 'Classics',
    'Computer-science' => 'Programming',
    'Cookbook' => 'Cooking',
    'Cookbooks' => 'Cooking',
    'Finance' => 'Economics',
    'Fitness' => 'Health',
    'Food' => 'Cooking',
    'Investing' => 'Economics',
    'Literature' => 'Classics',
    'Management' => 'Leadership',
    'Non-fiction' => 'Nonfiction',
    'Personal-development' => 'Personal Development',
    'Sci-fi' => 'Science Fiction',
    'Science-fiction' => 'Science Fiction',
    'Scifi' => 'Science Fiction',
    'Self-help' => 'Personal Development',
    'Self-improvement' => 'Personal Development',
    'Selfhelp' => 'Personal Development',
    'Software' => 'Programming',
    'Tech' => 'Technology',
    'Ya' => 'Young-adult',
    'Young-adult' => 'Young Adult'
  }.freeze

  CATEGORIES = [
    'Business',
    'Classics',
    'Cooking',
    'Design',
    'Economics',
    'Entrepreneurship',
    'Fantasy',
    'Fiction',
    'Health',
    'History',
    'Leadership',
    'Memoir',
    'Nonfiction',
    'Personal Development',
    'Philosophy',
    'Politics',
    'Programming',
    'Psychology',
    'Science Fiction',
    'Science',
    'Technology',
    'Writing',
    'Young Adult'
  ].freeze

  # Create a Book record from a Goodreads API request
  def update(book, mark_read, my_rating)
    self['Goodreads ID']      = book&.id
    self['ISBN']              = book&.isbn13
    self['Title']             = book&.title_without_series
    self['Description']       = sanitize(book.description)
    self['Cover']             = create_cover(book)
    self['Genres']            = merged_genres
    series, series_number     = create_series(book.title)
    self['Series']            = series
    self['Series Number']     = series_number
    self['Publication Year']  = book.publication_year&.to_s
    self['Goodreads Rating']  = book.average_rating&.to_f
    self['Personal Rating']   = my_rating if my_rating.positive?
    self['Goodreads URL']     = book&.link
    self['Pages']             = book.num_pages&.to_i
    authors                   = [book.authors.author].flatten
    self['Authors']           = create_authors(authors)
    self['Goodreads Ratings'] = book&.ratings_count&.to_i
    self['Read']              = mark_read
    save
  end

  def equals_to(book)
    return true if self['Goodreads ID'] == book.id
    return true if self['Title'] == book.title_without_series
    false
  end

  def need_to_update?(mark_read, my_rating)
    return true if my_rating.positive? && self['Personal Rating'] != my_rating
    return true if !!self['Read'] != !!mark_read
    false
  end

  def self.cached_genres
    @cached_genres ||= Genre.all.to_set
  end

  def self.create_genre(args = {})
    genre = Genre.create(args)
    @cached_genres.add(genre)
    genre
  end

  def self.cached_series
    @cached_series ||= Serie.all.to_set
  end

  def self.create_serie(args = {})
    serie = Serie.create(args)
    @cached_series.add(serie)
    serie
  end

  def self.cached_authors
    @cached_authors ||= Author.all.to_set
  end

  def self.create_author(args = {})
    author = Author.create(args)
    @cached_authors.add(author)
    author
  end

  private

  def merged_genres
    new_genres = create_genres(goodreads_genres)
    old_genres = Array(self['Genres'])
    old_genres + (new_genres - old_genres)
  end

  def sanitize(html_text)
    return '' unless html_text

    html_text
      .split(/\<.*?\>/)
      .map(&:strip)
      .reject(&:empty?)
      .join(' ')
      .gsub(/\s,/,',')
  end

  def create_cover(book)
    [
      {
        'url': book.image_url
      }
    ]
  end

  def create_genres(genres)
    genre_ids = []
    existing_genres = Book.cached_genres
    genres.each do |genre|
      genre = existing_genres.find { |a| a['Name'] == genre }
      genre ||= Book.create_genre('Name' => genre)
      genre_ids << genre.id
    end
    genre_ids
  end

  def goodreads_genres(n = 5)
    popular = goodreads_book.popular_shelves
    return [] if popular.blank?

    shelves = popular.shelf
    return [] unless shelves.first.respond_to?(:name)

    shelves
      .map(&:name)
      .reject { |name| GOODREADS_BLACKLIST.include?(name) }
      .first(n).map do |name|
        name = name.capitalize
        name = GOODREADS_MERGE[name] if GOODREADS_MERGE[name]
        (CATEGORIES.include?(name) && name) || nil
      end
      .compact.uniq
  end

  def goodreads_book
    @goodreads_book ||= GoodreadsClient::Client.book(self['Goodreads ID'])
  end

  # Create or find Series
  def create_series(title)
    return [], nil unless title[/\((.*?)\)/]

    series_title_with_number = title[/\((.*?)\)/][1..-2]
    series_title = series_title_with_number&.split('#')[0]&.tr('^a-zA-Z ', '')&.strip
    series_number = series_title_with_number&.split('#')[1]&.tr('^0-9.-', '')

    serie = Book.cached_series.find { |a| a['Title'] == series_title }
    serie ||= Book.create_serie('Title' => series_title)
    return [serie.id], series_number
  end

  # Create or find author
  def create_authors(authors)
    author_ids       = []
    existing_authors = Book.cached_authors
    authors.each do |author|
      existing_author = existing_authors.find { |a| a['Name'] == author.name }
      existing_author ||= Book.create_author('Name' => author.name)
      author_ids << existing_author.id
    end
    author_ids
  end
end
