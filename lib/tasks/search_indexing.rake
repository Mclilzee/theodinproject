namespace :search do
  desc 'index documents for searching'
  task index: :environment do
    Rails.logger.info 'Indexing content for searching...'
    tf_idf = TfIdfService.new
    search_indexer = SearchIndexer.new(tf_idf)
    search_indexer.index_frequencies(crawl: false)
  end

  desc 'Index documents including crawling the links'
  task crawl: :environment do
    Rails.logger.info 'Indexing content for searching...'
    tf_idf = TfIdfService.new
    search_indexer = SearchIndexer.new(tf_idf)
    search_indexer.index_frequencies(crawl: true)
  end
end
