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
      expect(rendered).to include('<h1>Home#index</h1>')
    end
  end

  describe "paragraph content" do
    it "displays the placeholder text" do
      expect(rendered).to include('Find me in app/views/home/index.html.erb')
    end

    it "renders deleted text" do
      expect(rendered).to include('<del>')
    end

    it "renders strikethrough text" do
      expect(rendered).to include('<s>')
    end

    it "renders inserted text" do
      expect(rendered).to include('<ins>')
    end

    it "renders underlined text" do
      expect(rendered).to include('<u>')
    end

    it "renders small text" do
      expect(rendered).to include('<small>')
    end

    it "renders bold text" do
      expect(rendered).to include('<strong>This line rendered as bold text.</strong>')
    end

    it "renders italicized text" do
      expect(rendered).to include('<em>This line rendered as italicized text.</em>')
    end
  end

  describe "heading hierarchy" do
    it "renders h2 heading" do
      expect(rendered).to include('<h2>Heading 2</h2>')
    end

    it "renders h3 heading" do
      expect(rendered).to include('<h3>Heading 3</h3>')
    end

    it "renders h4 heading" do
      expect(rendered).to include('<h4>Heading 4</h4>')
    end

    it "renders h5 heading" do
      expect(rendered).to include('<h5>Heading 5</h5>')
    end

    it "renders h6 heading" do
      expect(rendered).to include('<h6>Heading 6</h6>')
    end
  end

  describe "HTML structure" do
    it "wraps content in a div" do
      expect(rendered).to include('<div>')
    end

    it "contains multiple paragraph elements" do
      expect(rendered.scan(/<p>/).count).to be > 1
    end
  end
end
