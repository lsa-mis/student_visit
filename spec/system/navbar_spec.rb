require 'rails_helper'

RSpec.describe "Navigation", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  it "shows the navbar on the home page" do
    visit root_path
    expect(page).to have_css('nav')
  end

  it "can navigate to home using the navbar" do
    visit root_path
    within('nav') do
      click_link 'Student Visit'
    end
    expect(current_path).to eq(root_path)
  end

  # Add more tests as you add more navigation links
  # Example:
  # it "can navigate to about page" do
  #   visit root_path
  #   within('nav') do
  #     click_link 'About'
  #   end
  #   expect(current_path).to eq(about_path)
  # end
end 