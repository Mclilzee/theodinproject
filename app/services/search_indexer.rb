require 'nokogiri'

class SearchIndexer
  def initialize(tf_idf_service)
    @tf_idf = tf_idf_service
  end

  def index_frequencies
    # Lesson.find_each do |lesson|
    records = parse_lesson(Lesson.find(1))
    @tf_idf.populate_table(1, records)
    pp @tf_idf.list
    # end

    # save_to_database
  end

  def save_to_database
    list = @tf_idf.list
    progressbar = ProgressBar.create total: list.length, format: '%t: |%w%i| Saving Completed: %c %a %e'
    list.each do |table|
      search_record = SearchRecord.find_or_create_by(url: table[:url], title: table[:title], path: table[:path])
      bulk_records = table[:tf_idf].map do |word, score|
        { search_record_id: search_record.id, word:, score: }
      end
      TfIdf.upsert_all(bulk_records, unique_by: %i[search_record_id word])
      progressbar.increment
    end
  end

  def parse_lesson(lesson)
    doc = Nokogiri::HTML5.parse(lesson.body)
    doc.css('section:not(#content)').map do |section|
      anchor = section.at('h3 a')
      slug = anchor['href']
      title = anchor.text

      { slug:, title:, text: section.text + lesson.description }
    end
  end
end
