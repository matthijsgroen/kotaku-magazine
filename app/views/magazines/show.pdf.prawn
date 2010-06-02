require "open-uri"

## now build our PDF from HTML pages.

	cover_page = @magazine.pages.of_type("cover").first
	cover_content = Hpricot(remove_double_breaks(cover_page.html_content), :fixup_tags => true)
	include_images pdf, (cover_content / "img:first").remove
  create_pdf_article pdf, cover_content, @magazine, "Table of contents", "Introduction"

	[@magazine.pages[7]].each do |page|
		unless page.classification == "cover" then
			page_content = Hpricot(remove_double_breaks(page.html_content), :fixup_tags => true)
			create_pdf_article pdf, page_content, @magazine, "#{page.classification.upcase} - #{page.title}", page.title
		end
	end

