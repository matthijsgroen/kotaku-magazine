class MagazinesController < ApplicationController

	def index
		@magazines = Magazine.all
  end

  def show
		@magazine = Magazine.find params[:id]

		respond_to do |format|
			format.html # show.html.erb
			format.pdf {
				prawnto :prawn=> {
					:page_layout => :portrait,
					:page_size => 'A4',
					:left_margin => 0,
					:right_margin => 0,
					:top_margin => 0,
					:bottom_margin => 0,
					:info => {
						:Title => @magazine.issue_name, :Author => "Matthijs Groen",
						:CreationDate => Time.now
					}
				}, :inline => false
				render :layout => false
			} # show.pdf.prawn
		end
	end

  def edit
		@magazine = Magazine.find params[:id]
  end

	def update
		@magazine = Magazine.find params[:id]
		@magazine.update_attributes params[:magazine]
		@magazine.crawl_contents
		redirect_to @magazine
	end

  def new
		@magazine = Magazine.new
	end

	def create
		@magazine = Magazine.new params[:magazine]
		@magazine.crawl_contents
		redirect_to @magazine
	end

	def destroy
		@magazine = Magazine.find params[:id]
		@magazine.destroy

		redirect_to magazines_url
	end

end
