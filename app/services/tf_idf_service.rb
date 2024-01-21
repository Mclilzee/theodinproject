class TfIdfService
  def initialize
    @stop_words = stop_words
    @df_table = Hash.new(0)
    @tf_table = {}
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
    @total_documents += 1
    records.each { |record| tokenize(lesson_id, record) }
  end

  def tokenize(lesson_id, record)
    tf_map = Hash.new(0)
    words = "#{record[:title]} #{record[:text]}".scan(/\b\w+\b/)
    words.each do |word|
      next if @stop_words.include?(word)

      word = word.downcase
      tf_map[word] += 1
      @df_table[word] += 1 if tf_map[word] == 1
    end

    @tf_table[lesson_id] = { slug: record[:slug], tf_map: }
  end

  def list
    @tf_table.map do |url, record|
      tf_idf = record[:tf_map].map do |word, _|
        score = calculate_tf_idf_score(url, word)
        [word, score]
      end

      { url:, title: record[:title], path: record[:path], tf_idf: }
    end
  end

  def calculate_tf_idf_score(url, word)
    tf_table = @tf_table[url][:tf_map]
    total_tf = tf_table.length
    tf = tf_table[word]
    df = @df_table[word]
    ((tf.to_f / total_tf) * Math.log((1 + @total_documents.to_f) / (1 + df)))
  end
end
