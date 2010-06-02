class AddClassificationToIssuePage < ActiveRecord::Migration
  def self.up
		add_column :issue_pages, :classification, :string
  end

  def self.down
		remove_column :issue_pages, :classification
  end
end
