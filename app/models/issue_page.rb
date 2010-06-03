class IssuePage < ActiveRecord::Base
  belongs_to :issue, :class_name => "Magazine"

	named_scope :of_type do |type_name| { :conditions => { :classification => type_name }, :order => "article_nr ASC" } end

	def crawl_page_content
		#http://kotaku.com/5551512/k-monthly-+-may-2010?skyline=true&s=i
		uri = URI.parse url
		server = Net::HTTP.new(uri.host, uri.port ? uri.port : PROTOCOL_PORT_MAPPING[uri.scheme])
		server.use_ssl = %w(https).include?(uri.scheme) ? true : false

		response = server.get "#{uri.path}?#{uri.query}", {}
		raise "Pagina kon niet worden geladen van #{uri.host}" unless (response.code == "200")
		page = Hpricot(response.body, :fixup_tags => true)
		content = (page / "#wrapper .content")
		(content / ".welcome_form, #agegate_container, #agegate_container_rejected, script, noscript").remove

		self.title = (content / "h1:first").to_s.strip_tags
		(content / ".ad_editorial-sponsorship, .permalink_ads, .commenter_area, h1:first").remove

		self.html_content = content.to_s
	end
	
	def crawl_toc
		page = Hpricot(self.html_content, :fixup_tags => true)
		counter = 1
		(page / "ul li").each do |article|
			counter += 1 
			section = (article.parent.preceding.filter "h2:last").first.inner_text.downcase
			link_url = article.at("a").attributes["href"]

			begin
				uri = URI.parse link_url
				page = issue.pages.build :url => link_url, :article_nr => counter, :classification => section
				page.crawl_page_content
				page.save
			rescue
			end
		end
	end

end
