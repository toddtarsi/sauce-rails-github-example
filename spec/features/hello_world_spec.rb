require 'spec_helper'

describe 'Hello World' do
  it 'loads the page', type: :feature do
    visit '/'
    expect(page).to have_css('h1', exact_text: 'Hello World')
  end
end
