require 'rubygems'
require 'hpricot'

class Magazine < ActiveRecord::Base
	has_many :pages, :class_name => "IssuePage", :foreign_key => :issue_id, :dependent => :destroy

	PROTOCOL_PORT_MAPPING = {
		"http" => 80,
		"https" => 443
	}

	def crawl_contents
		pages.each(&:destroy)
		self.issue_name = "test"
		self.save

		start_page = pages.build :url => url, :article_nr => 1, :classification => "cover"
		start_page.crawl_page_content
		start_page.save
		start_page.crawl_toc
	end


end
