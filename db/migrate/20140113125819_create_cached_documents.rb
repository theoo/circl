class CreateCachedDocuments < ActiveRecord::Migration
  def change
    create_table :cached_documents do |t|
      t.integer :validity_time
      t.timestamps
    end
    add_index :cached_documents, :created_at

    add_attachment :cached_documents, :document

  end
end
