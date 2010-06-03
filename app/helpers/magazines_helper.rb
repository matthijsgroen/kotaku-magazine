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
		pdf.start_new_page(:left_margin => 50, :right_margin => 50, :top_margin => 60, :bottom_margin => 50)
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
			pdf.image open("#{Rails.public_path}/images/background_tile.jpg"), :at => [-50, 800], :width => 40, :height => 900
			pdf.image open("#{Rails.public_path}/images/logo.png"), :at => [-30, 780], :height => 30
			if title.blank?
				pdf.draw_text "#{section_name}", :at => [100, 780]
			else
				pdf.draw_text "#{section_name}", :at => [90, 765], :size => 12, :style => :bold
				pdf.draw_text "#{title}", :at => [90, 755], :size => 8, :style => :italic
			end

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
				when "strike", "s" then return wrap_element(element, options, "strikethrough")
				when "center" then return change_markup(element, { :align => :center }.reverse_merge(options))
				when "span" then return parse_span(element, options)
				when "font" then return parse_font(element, options)
				when "div" then return element.children.collect { |element| parse_element element, options } if element.children
				when "h2", "h3" then return parse_children_as(:header, element, { :prefix => "\n"}.reverse_merge(options))
				when "ul" then return change_markup(element, { :indent => (options[:indent] || 0) + 20 }.reverse_merge(options))
				when "li" then return parse_children_as(:bullet, element, { :prefix => "<color rgb=\"#ea1953\">*</color> "}.reverse_merge(options))
				when "br" then return { :type => :text, :content => "" }
				# ignore these elements
				when "form" then return nil
				else raise "unknown: #{element.name}: #{element.to_s}"
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

	def parse_span(element, options)
		prefix = ""
		postfix = ""
		if style = element.attributes["style"]
			rules = {}
			style.split(";").each { |rule| key, value = rule.split(":"); rules[key.strip] = value.strip }
			if color = rules["color"]
				color = fix_color(color)
				prefix += "<color rgb=\"##{color}\">"
				postfix = "</color>\n" + postfix
			end
		end
		parse_children_as(:text, element, { :prefix => prefix, :postfix => postfix }.reverse_merge(options))
	end

	def parse_font(element, options)
		prefix = ""
		postfix = ""
		if color = element.attributes["color"]
			color = fix_color(color)
			prefix += "<color rgb=\"##{color}\">"
			postfix = "</color>\n" + postfix
		end
		parse_children_as(:text, element, { :prefix => prefix, :postfix => postfix }.reverse_merge(options))
	end

	HTML_COLOR_MAP = {
		"AliceBlue" => "#F0F8FF",
		"AntiqueWhite" => "#FAEBD7",
		"Aqua" => "#00FFFF",
		"Aquamarine" => "#7FFFD4",
		"Azure" => "#F0FFFF",
		"Beige" => "#F5F5DC",
		"Bisque" => "#FFE4C4",
		"Black" => "#000000",
		"BlanchedAlmond" => "#FFEBCD",
		"Blue" => "#0000FF",
		"BlueViolet" => "#8A2BE2",
		"Brown" => "#A52A2A",
		"BurlyWood" => "#DEB887",
		"CadetBlue" => "#5F9EA0",
		"Chartreuse" => "#7FFF00",
		"Chocolate" => "#D2691E",
		"Coral" => "#FF7F50",
		"CornflowerBlue" => "#6495ED",
		"Cornsilk" => "#FFF8DC",
		"Crimson" => "#DC143C",
		"Cyan" => "#00FFFF",
		"DarkBlue" => "#00008B",
		"DarkCyan" => "#008B8B",
		"DarkGoldenRod" => "#B8860B",
		"DarkGray" => "#A9A9A9",
		"DarkGreen" => "#006400",
		"DarkKhaki" => "#BDB76B",
		"DarkMagenta" => "#8B008B",
		"DarkOliveGreen" => "#556B2F",
		"Darkorange" => "#FF8C00",
		"DarkOrchid" => "#9932CC",
		"DarkRed" => "#8B0000",
		"DarkSalmon" => "#E9967A",
		"DarkSeaGreen" => "#8FBC8F",
		"DarkSlateBlue" => "#483D8B",
		"DarkSlateGray" => "#2F4F4F",
		"DarkTurquoise" => "#00CED1",
		"DarkViolet" => "#9400D3",
		"DeepPink" => "#FF1493",
		"DeepSkyBlue" => "#00BFFF",
		"DimGray" => "#696969",
		"DodgerBlue" => "#1E90FF",
		"FireBrick" => "#B22222",
		"FloralWhite" => "#FFFAF0",
		"ForestGreen" => "#228B22",
		"Fuchsia" => "#FF00FF",
		"Gainsboro" => "#DCDCDC",
		"GhostWhite" => "#F8F8FF",
		"Gold" => "#FFD700",
		"GoldenRod" => "#DAA520",
		"Gray" => "#808080",
		"Green" => "#008000",
		"GreenYellow" => "#ADFF2F",
		"HoneyDew" => "#F0FFF0",
		"HotPink" => "#FF69B4",
		"IndianRed" => "	#CD5C5C",
		"Indigo" => "	#4B0082",
		"Ivory" => "#FFFFF0",
		"Khaki" => "#F0E68C",
		"Lavender" => "#E6E6FA",
		"LavenderBlush" => "#FFF0F5",
		"LawnGreen" => "#7CFC00",
		"LemonChiffon" => "#FFFACD",
		"LightBlue" => "#ADD8E6",
		"LightCoral" => "#F08080",
		"LightCyan" => "#E0FFFF",
		"LightGoldenRodYellow" => "#FAFAD2",
		"LightGrey" => "#D3D3D3",
		"LightGreen" => "#90EE90",
		"LightPink" => "#FFB6C1",
		"LightSalmon" => "#FFA07A",
		"LightSeaGreen" => "#20B2AA",
		"LightSkyBlue" => "#87CEFA",
		"LightSlateGray" => "#778899",
		"LightSteelBlue" => "#B0C4DE",
		"LightYellow" => "#FFFFE0",
		"Lime" => "#00FF00",
		"LimeGreen" => "#32CD32",
		"Linen" => "#FAF0E6",
		"Magenta" => "#FF00FF",
		"Maroon" => "#800000",
		"MediumAquaMarine" => "#66CDAA",
		"MediumBlue" => "#0000CD",
		"MediumOrchid" => "#BA55D3",
		"MediumPurple" => "#9370D8",
		"MediumSeaGreen" => "#3CB371",
		"MediumSlateBlue" => "#7B68EE",
		"MediumSpringGreen" => "#00FA9A",
		"MediumTurquoise" => "#48D1CC",
		"MediumVioletRed" => "#C71585",
		"MidnightBlue" => "#191970",
		"MintCream" => "#F5FFFA",
		"MistyRose" => "#FFE4E1",
		"Moccasin" => "#FFE4B5",
		"NavajoWhite" => "#FFDEAD",
		"Navy" => "#000080",
		"OldLace" => "#FDF5E6",
		"Olive" => "#808000",
		"OliveDrab" => "#6B8E23",
		"Orange" => "#FFA500",
		"OrangeRed" => "#FF4500",
		"Orchid" => "#DA70D6",
		"PaleGoldenRod" => "#EEE8AA",
		"PaleGreen" => "#98FB98",
		"PaleTurquoise" => "#AFEEEE",
		"PaleVioletRed" => "#D87093",
		"PapayaWhip" => "#FFEFD5",
		"PeachPuff" => "#FFDAB9",
		"Peru" => "#CD853F",
		"Pink" => "#FFC0CB",
		"Plum" => "#DDA0DD",
		"PowderBlue" => "#B0E0E6",
		"Purple" => "#800080",
		"Red" => "#FF0000",
		"RosyBrown" => "#BC8F8F",
		"RoyalBlue" => "#4169E1",
		"SaddleBrown" => "#8B4513",
		"Salmon" => "#FA8072",
		"SandyBrown" => "#F4A460",
		"SeaGreen" => "#2E8B57",
		"SeaShell" => "#FFF5EE",
		"Sienna" => "#A0522D",
		"Silver" => "#C0C0C0",
		"SkyBlue" => "#87CEEB",
		"SlateBlue" => "#6A5ACD",
		"SlateGray" => "#708090",
		"Snow" => "#FFFAFA",
		"SpringGreen" => "#00FF7F",
		"SteelBlue" => "#4682B4",
		"Tan" => "#D2B48C",
		"Teal" => "#008080",
		"Thistle" => "#D8BFD8",
		"Tomato" => "#FF6347",
		"Turquoise" => "#40E0D0",
		"Violet" => "#EE82EE",
		"Wheat" => "#F5DEB3",
		"White" => "#FFFFFF",
		"WhiteSmoke" => "#F5F5F5",
		"Yellow" => "#FFFF00"
	}

	LOOKUP_HTML_COLORS = returning({}) do |map|
		HTML_COLOR_MAP.each { |key, value| map[key.upcase] = value }
	end

	def fix_color(color)
		org_color = color.dup
		if color.starts_with? "#"
			color = color[1..color.length]
			color = color[0,1] * 2 + color[1,1] * 2 + color[2,1] * 2 if color.length == 3
		else
			color = LOOKUP_HTML_COLORS[color.upcase]
		end
		raise "color not found: #{org_color}" if color.nil?
		color
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
		[apply_markup({ :type => type, :content => (options.delete(:prefix) || ""), :clear => options[:clear].nil? ? true : options[:clear] }, options)] +  
		header.children.collect { |element| parse_element element, options }.flatten.compact.collect do |content|
			content[:type] = type if content[:type] == :text
			content
		end +
		[apply_markup({ :type => type, :content => (options.delete(:postfix) || "") }, options)]
	end

	def apply_markup(content, markup)
		content[:align] ||= markup[:align] || :left
		content[:indent] ||= markup[:indent] || 0
		content
	end

	def remove_double_breaks(text)
		text.gsub("&mdash;", "-")
		text.gsub("\n", "")
	end

end
