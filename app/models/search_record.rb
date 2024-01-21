class SearchRecord < ApplicationRecord
  belongs_to :lesson

  has_many :tf_idf, dependent: :destroy
  validates :slug, presence: true
end
