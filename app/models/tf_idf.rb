class TfIdf < ApplicationRecord
  belongs_to :search_record

  validates :word, presence: true
  validates :tf_idf, presence: true
end