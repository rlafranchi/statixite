class CreateStatixiteSites < ActiveRecord::Migration
  def change
    create_table :statixite_sites do |t|
      t.string :site_name
      t.string :domain_name
      t.string :template
      t.json   :settings, default: {}, null: false
      t.string :build_option
      t.string :template_repo
      t.string :hostname
      t.timestamps
    end
    add_index :statixite_sites, :site_name, :unique => true
  end
end
