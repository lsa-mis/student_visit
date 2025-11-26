require 'rails_helper'

RSpec.describe "home/index.html.erb", type: :view do
  before do
    render template: 'home/index'
  end

  it "renders without errors" do
    expect(rendered).to be_present
  end

  describe "main heading" do
    it "displays the main heading" do
      expect(rendered).to include('Student Visit Application')
    end
  end

  describe "paragraph content" do
    it "displays the login prompt" do
      expect(rendered).to include('Please log in to continue')
    end
  end

  describe "HTML structure" do
    it "wraps content in a div" do
      expect(rendered).to include('<div class="container')
    end

    it "contains a login link" do
      expect(rendered).to include('Log In')
    end
  end
end
