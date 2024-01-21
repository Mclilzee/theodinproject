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
      save_bulk(record, search_record.id)
      progressbar.increment
    end
  end

  def save_bulk(record, search_record_id)
    bulk_records = record[:tf_idf].filter_map do |word, score|
      next if word.length > 20

      { search_record_id:, word:, score: }
    end
    TfIdf.upsert_all(bulk_records, unique_by: %i[search_record_id word])
  end

  def parse_lesson(lesson)
    doc = Nokogiri::HTML5.parse(lesson.body)
    doc.css('a[href]').each do |link|
      url = link[:href]
      if valid_link(url)
        @external_links[url] = link.text
      end
    end

    { url: "https://www.theodinproject.com/lessons/#{lesson.slug}", title: lesson.title, path: lesson.path.slug, text: doc.text }
  end

  def parse_external_links
    progressbar = ProgressBar.create total: @external_links.length, format: '%t: |%w%i| Crawling Completed: %c %a %e'
    thread_pool = Concurrent::FixedThreadPool.new(8)
    @external_links.each do |url, title|
      thread_pool.post(url, title) do |thread_url, thread_title|
        parse_url(thread_url, thread_title)
        progressbar.increment
      end
    end
    thread_pool.shutdown
    thread_pool.wait_for_termination
  end

  def parse_url(url, title)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)

    text = Nokogiri::HTML5.parse(response.body).text
    @tf_idf.populate_table({ url:, title:, text: })
  rescue StandardError => e
    Rails.logger.error(e)
  end

  def valid_link(url)
    url.start_with?('http') && !url.end_with?('.jpg', '.jpeg', '.png', '.gif', '.bmp')
  end
end
