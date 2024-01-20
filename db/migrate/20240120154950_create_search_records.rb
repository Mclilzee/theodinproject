class CreateSearchRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :search_records do |t|
      t.string :url, null: false, unique: true
      t.string :title, null: false
      t.string :path, null: false
    end
  end
end
