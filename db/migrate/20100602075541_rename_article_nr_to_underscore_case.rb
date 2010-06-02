class RenameArticleNrToUnderscoreCase < ActiveRecord::Migration
  def self.up
		rename_column :issue_pages, :articleNr, :article_nr
  end

  def self.down
		rename_column :issue_pages, :article_nr, :articleNr
  end
end
