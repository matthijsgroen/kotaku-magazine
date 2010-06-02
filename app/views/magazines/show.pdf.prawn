require "open-uri"

## now build our PDF from HTML pages.

	cover_page = @magazine.pages.of_type("cover").first
	cover_content = Hpricot(cover_page.html_content, :fixup_tags => true)

	include_images pdf, (cover_content / "img:first").remove

  #create_pdf_page pdf, cover_content
