class AddTitleToArticlePage < ActiveRecord::Migration
  def self.up
		add_column :issue_pages, :title, :string
  end

  def self.down
		remove_column :issue_pages, :title
  end
end
