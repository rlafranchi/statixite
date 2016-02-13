class CreateStatixiteDeployments < ActiveRecord::Migration
  def change
    create_table :statixite_deployments do |t|
      t.string :version
      t.string :sha
      t.integer :site_id
      t.timestamps
    end
    add_index :statixite_deployments, :site_id
  end
end
