module MagazinesHelper

	def include_images(pdf, image_selection)
		image_selection.each do |image|
			image_url = image.parent.attributes["href"]
			image_url ||= image.attributes["src"]
			#pdf.text image_url
			pdf.image open(image_url)
		end
	end

end
