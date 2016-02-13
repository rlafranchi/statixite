class CreateStatixitePosts < ActiveRecord::Migration
  def change
    create_table :statixite_posts do |t|
      t.string  :title
      t.text    :content
      t.integer :site_id
      t.json    :front_matter, default: {}, null: false
      t.string  :slug
      t.string  :filename
      t.timestamps
    end
    add_index :statixite_posts, :site_id
  end
end
