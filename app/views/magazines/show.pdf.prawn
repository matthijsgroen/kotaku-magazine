require "open-uri"

## now build our PDF from HTML pages.

	cover_page = @magazine.pages.of_type("cover").first
	cover_content = Hpricot(remove_double_breaks(cover_page.html_content), :fixup_tags => true)
	include_images pdf, (cover_content / "img:first").remove
  create_pdf_article pdf, cover_content, @magazine, "Table of contents", "Introduction"

	@magazine.pages.each do |page|
		unless page.classification == "cover" then
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
	create_pdf_article pdf, last_page_content, @magazine, "Credits for compilation", "End of issue"
