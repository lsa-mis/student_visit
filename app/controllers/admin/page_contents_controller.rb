class Admin::PageContentsController < ApplicationController
  before_action :set_page_content, only: [ :show, :edit, :update, :destroy ]

  def index
    @page_contents = authorize policy_scope(PageContent).order(:page_path, :area_name)
    @pages = @page_contents.group_by(&:page_path)
  end

  def show
  end

  def new
    @page_content = authorize PageContent.new
  end

  def create
    @page_content = authorize PageContent.new(page_content_params)

    if @page_content.save
      redirect_to admin_page_contents_path, notice: "Page content was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @page_content.update(page_content_params)
      redirect_to admin_page_contents_path, notice: "Page content was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @page_content.destroy
    redirect_to admin_page_contents_path, notice: "Page content was successfully deleted."
  end

  private

  def set_page_content
    @page_content = authorize policy_scope(PageContent).find(params[:id])
  end

  def page_content_params
    params.require(:page_content).permit(:page_path, :area_name, :content)
  end
end
