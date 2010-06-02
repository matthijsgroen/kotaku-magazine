module MagazinesHelper

	def include_images(pdf, image_selection)
		image_selection.each do |image|
			image_url = image.parent.attributes["href"]
			image_url ||= image.attributes["src"]
			#pdf.text image_url
			pdf.image open(image_url)
		end
	end

	def create_pdf_article(pdf, content, issue, section_name, title = "")
		pdf.start_new_page(:left_margin => 50, :right_margin => 50, :top_margin => 50, :bottom_margin => 50)
		start_page = pdf.page_count
		(content / ".gallery_image, .gallery_pre").remove

		picture_gallery = (content / "#thumb_list").remove

		pdf_elements = content.children.first.children.collect { |element| parse_element element }.flatten.compact

		pdf.text "<color rgb=\"#ea1953\">#{title}</color>", :align => :center, :size => 18, :inline_format => true unless title.blank?

		merged_elements = []
		pdf_elements.each do |element|
			last = merged_elements.last || { :type => :unknown }
			if element[:type] == last[:type] and same_style?(element, last)
				last[:content] += element[:content]
			else
				merged_elements << element
			end
		end
		merged_elements.each do |element|
			case element[:type]
				when :text then begin
					pdf.indent(element[:indent] || 0) do
						text = element[:content]
						text += "\n" unless text.ends_with? "\n"
						pdf.text text, :inline_format => true, :align => (element[:align] || :left), :leading => 5
					end
				end
				when :header then begin
					pdf.text element[:content], :inline_format => true, :align => (element[:align] || :left), :size => 14, :leading => 15
				end
				when :bullet then begin
					pdf.indent(element[:indent] || 0) do
						pdf.text element[:content], :inline_format => true, :align => (element[:align] || :left), :leading => 5
					end
				end
				when :image then begin
					pdf.image open(element[:content]), :max => [500, 700], :align => :center
					pdf.text " "
				end
			end
		end
		if picture_gallery
			(picture_gallery / "img").collect do |image|
				pdf.image open(image.attributes["src"].gsub("gallery_", "")), :max => [500, 700], :align => :center
				pdf.text " "
			end
		end

		(start_page .. pdf.page_count).each do |index|
			pdf.go_to_page(index)
			pdf.draw_text "#{section_name}", :at => [0, 760]
			
			pdf.draw_text "#{issue.issue_name} - Page #{index}", :at => [0, -30]
		end
	end

	def same_style?(a, b)
		a[:align] == b[:align] and
		a[:indent] == b[:indent] and not a[:clear]
	end

	def parse_element(element, options = {})
		if element.elem?
			case element.name
				when "p" then return parse_paragraph(element, options)
				when "a" then return parse_link(element, options)
				when "img" then return parse_image(element, options)
				when "em", "i" then return wrap_element(element, options, "i")
				when "strong", "b" then return wrap_element(element, options, "b")
				when "center" then return change_markup(element, { :align => :center }.reverse_merge(options))
				when "div" then return element.children.collect { |element| parse_element element, options } if element.children 
				when "h2" then return parse_children_as(:header, element, { :prefix => "\n"}.reverse_merge(options))
				when "ul" then return change_markup(element, { :indent => (options[:indent] || 0) + 20 }.reverse_merge(options))
				when "li" then return parse_children_as(:bullet, element, { :prefix => "<color rgb=\"#ea1953\">*</color> "}.reverse_merge(options))
				when "br" then return { :type => :text, :content => "" }
				else return { :type => :text, :content => "unknown: #{element.name}" }
			end
		elsif element.text?
			return apply_markup({ :type => :text, :content => element.inner_text }, options) unless element.inner_text.blank?
		end
		nil
	end

	def wrap_element(element, options, wrap)
		[apply_markup({ :type => :text, :content => "<#{wrap}>" }, options)] + element.children.collect { |element| parse_element element, options } +
			[apply_markup({ :type => :text, :content => "</#{wrap}>" }, options)]
	end

	def change_markup(element, options)
		element.children.collect { |element| parse_element element, options }
	end

	def parse_paragraph(paragraph, options)
		result = [apply_markup({ :type => :text, :content => "\n" }, options)]
		result += paragraph.children.collect { |element| parse_element element, options } if paragraph.children
		result
	end

	def parse_link(link, options)
		return apply_markup({ :type => :text, :content => "<link href=\"#{link.attributes["href"]}\"><color rgb=\"#ea1953\">#{link.inner_text}</color></link>" }, options) unless link.inner_text.blank?
		nil
	end

	def parse_image(image, options)
		return { :type => :image, :content => image.attributes["src"] }
	end

	def parse_children_as(type, header, options)
		[apply_markup({ :type => type, :content => (options.delete(:prefix) || ""), :clear => true }, options)] +  
		header.children.collect { |element| parse_element element, options }.flatten.compact.collect do |content|
			content[:type] = type if content[:type] == :text
			content
		end
	end

	def apply_markup(content, markup)
		content[:align] ||= markup[:align] || :left
		content[:indent] ||= markup[:indent] || 0
		content
	end

	def remove_double_breaks(text)
		text.gsub("\n", "")
	end

end
