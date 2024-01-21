class TfIdfService
  def initialize
    @stop_words = stop_words
    @df_table = Hash.new(0)
    @tf_list = []
    @total_documents = 0
  end

  def stop_words
    Set.new(%w[
              a an and are as at be by for from has he in is it its of on that the to was were will with I you your
              yours him his she her hers they them their theirs we us our ours this these those who whom whose what
              which where when why how am being been do does did have had having me my mine myself yourself yourselves
              himself herself itself themselves ourselves but or nor so yet up down over under above below between among
              through out off about against during here there all any both each few more most other some such no not
              same another own certain first last next many much good great new big man one two
              three four five six seven eight nine ten
            ])
  end

  def populate_table(lesson_id, records)
    @total_documents += records.length
    sections = records.map { |record| tokenize(record) }
    @tf_list << { lesson_id:, sections: }
  end

  def tokenize(record)
    tf_map = Hash.new(0)
    words = "#{record[:title]} #{record[:text]}".scan(/\b\w+\b/)
    words.each do |word|
      next if @stop_words.include?(word)

      word = word.downcase
      tf_map[word] += 1
      @df_table[word] += 1 if tf_map[word] == 1
    end
    { slug: record[:slug], title: record[:title], tf_map: }
  end

  def list
    @tf_list.map do |record|
      sections = record[:sections].map do |section|
        calculate_tf_idf_section(section)
      end
      { lesson_id: record[:lesson_id], sections: }
    end
  end

  def calculate_tf_idf_section(section)
    table = section[:tf_map]
    tf_idf = table.map do |word, tf|
      df = @df_table[word]
      score = ((tf.to_f / table.length) * Math.log((1 + @total_documents.to_f) / (1 + df)))
      [word, score]
    end

    { slug: section[:slug], title: section[:title], tf_idf: }
  end
end
