require 'nokogiri'
require 'net/http'
require 'uri'

class SearchIndexer
  def initialize(tf_idf_service)
    @tf_idf = tf_idf_service
    @external_links = {}
  end

  def index_frequencies(config)
    Lesson.find_each do |lesson|
      record = parse_lesson(lesson)
      @tf_idf.populate_table(record)
    end

    if config[:crawl]
      parse_external_links
    end
    populate_database
  end

  def populate_database
    list = @tf_idf.list
    progressbar = ProgressBar.create total: list.length, format: '%t: |%w%i| Saving Completed: %c %a %e'
    list.each do |record|
      search_record = SearchRecord.find_or_create_by(url: record[:url], title: record[:title], path: record[:path])
      bulk_records = record[:tf_idf].map do |word, score|
        { search_record_id: search_record.id, word:, score: }
      end
      TfIdf.upsert_all(bulk_records, unique_by: %i[search_record_id word])
      progressbar.increment
    end
  end

  def parse_lesson(lesson)
    doc = Nokogiri::HTML5.parse(lesson.body)
    doc.css('a[href]').each do |link|
      href = link[:href]
      @external_links[href] = link.text
    end

    { url: "https://www.theodinproject.com/lessons/#{lesson.slug}", title: lesson.title, path: lesson.path.slug, text: doc.text }
  end

  def parse_external_links
    progressbar = ProgressBar.create total: @external_links.length, format: '%t: |%w%i| Crawling Completed: %c %a %e'
    valid_links.each do |url, title|
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      next unless response.is_a?(Net::HTTPSuccess)

      @tf_idf.populate_table({ url:, title:, path: 'external', text: Nokogiri::HTML5.parse(response.body).text })
      progressbar.increment
    rescue StandardError => _e
      puts "Error: #{url}"
    end
  end

  def valid_links
    @external_links.select do |url|
      url.start_with?('http')
    end
  end
end
