class CreateStatixiteMedia < ActiveRecord::Migration
  def change
    create_table :statixite_media do |t|
      t.string :file
      t.integer :site_id
      t.timestamps
    end
    add_index :statixite_media, :site_id
  end
end
