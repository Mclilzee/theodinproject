class SearchRecord < ApplicationRecord
  belong_to :lesson

  has_many :tf_idf, dependent: :destroy
  validates :slug, presence: true
end
