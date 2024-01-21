require 'nokogiri'

class SearchIndexer
  def initialize(tf_idf_service)
    @tf_idf = tf_idf_service
  end

  def index_frequencies
    Lesson.each do |lesson|
      records = parse_lesson(lesson)
      @tf_idf.populate_table(lesson.id, records)
    end

    # save_to_database
  end

  def save_to_database
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
    doc.xpath('//section').map do |section|
      anchor = section.at('h3 a')
      slug = anchor['href']
      title = anchor.text

      { slug:, title:, text: section.text }
    end
  end
end
