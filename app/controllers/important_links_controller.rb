class ImportantLinksController < ApplicationController
  before_action :set_program
  before_action :set_important_link, only: [ :show, :edit, :update, :destroy ]

  def index
    @important_links = policy_scope(ImportantLink).where(program: @program).ordered
    authorize ImportantLink.new(program: @program)
  end

  def show
    authorize @important_link
  end

  def new
    @important_link = @program.important_links.build
    authorize @important_link
  end

  def create
    @important_link = @program.important_links.build(important_link_params)
    authorize @important_link

    if @important_link.save
      redirect_to department_program_important_link_path(@program.department, @program, @important_link), notice: "Important link was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @important_link
  end

  def update
    authorize @important_link

    if @important_link.update(important_link_params)
      redirect_to department_program_important_link_path(@program.department, @program, @important_link), notice: "Important link was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @important_link
    @important_link.destroy
    redirect_to department_program_important_links_path(@program.department, @program), notice: "Important link was successfully deleted."
  end

  private

  def set_program
    @program = Program.find(params[:program_id])
    @department = @program.department
  end

  def set_important_link
    @important_link = @program.important_links.find(params[:id])
  end

  def important_link_params
    params.require(:important_link).permit(:name, :url, :ranking)
  end
end
