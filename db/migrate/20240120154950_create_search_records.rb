class CreateSearchRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :search_records do |t|
      t.string :slug, null: false
      t.belongs_to :lesson, foreign_key: true, null: false
    end
  end
end
