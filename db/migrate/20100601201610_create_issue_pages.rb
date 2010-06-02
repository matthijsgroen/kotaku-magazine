class CreateIssuePages < ActiveRecord::Migration
  def self.up
    create_table :issue_pages do |t|
      t.references :issue
      t.integer :articleNr
      t.text :html_content

      t.timestamps
    end
  end

  def self.down
    drop_table :issue_pages
  end
end
