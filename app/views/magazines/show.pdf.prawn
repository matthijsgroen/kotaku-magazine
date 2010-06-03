require "open-uri"

## now build our PDF from HTML pages.

  @page_index = {}
	@magazine.pages.each { |page| @page_index[page.url] = page.page_nr }

	cover_page = @magazine.pages.of_type("cover").first
	cover_content = Hpricot(remove_double_breaks(cover_page.html_content), :fixup_tags => true)
	include_images pdf, (cover_content / "img:first").remove
  create_pdf_article pdf, cover_content, @magazine, "Table of contents", "Introduction"

	@magazine.pages.each do |page|
		unless page.classification == "cover" then
			page.update_attribute :page_nr, pdf.page_count + 1

			page_content = Hpricot(remove_double_breaks(page.html_content), :fixup_tags => true)
			create_pdf_article pdf, page_content, @magazine, "#{page.classification.upcase}", page.title
		end
	end

	last_page_content = <<-EndOfIssue
	<div>
		<h2>About this PDF issue</h2>
		<p>
			This issue is created by Matthijs Groen, with the use of Ruby on Rails, Hpricot and Prawn.
			The sourcecode is available through <a href="http://github.com/matthijsgroen/kotaku-magazine">Github</a>.
		</p>
		<p>
			You can reach Matthijs at <a href="mailto:matthijs.groen@gmail.com">matthijs.groen@gmail.com</a>
		</p>
	</div>
	EndOfIssue
	create_pdf_article pdf, Hpricot(remove_double_breaks(last_page_content), :fixup_tags => true), @magazine, "Credits for compilation", "End of issue"

	sections = @magazine.pages.collect(&:classification).uniq - ["cover"]

	if sections
		pdf.define_outline do |outline|
			sections.each do |issue_section|
				articles = @magazine.pages.find :all, :conditions => { :classification => issue_section }, :order => "article_nr ASC"

				outline.add_section do
					section issue_section, :page => articles.first.page_nr.to_i, :closed => true do
						articles.each do |article|
							page article.page_nr.to_i, :title => article.title
						end
					end
				end
			end
		end

	end
