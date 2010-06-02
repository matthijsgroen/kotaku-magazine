class AddUrlToIssuePage < ActiveRecord::Migration
  def self.up
		add_column :issue_pages, :url, :string
  end

  def self.down
		remove_column :issue_pages, :url		
  end
end
