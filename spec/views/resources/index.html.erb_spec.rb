require 'rails_helper'

RSpec.describe "resources/index", type: :view do
  before(:each) do
    assign(:resources, [
      Resource.create!(
        :file => "File"
      ),
      Resource.create!(
        :file => "File"
      )
    ])
  end

  it "renders a list of resources" do
    render
    assert_select "tr>td", :text => "File".to_s, :count => 2
  end
end
