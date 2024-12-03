# spec/lib/parse_name_spec.rb
# bundle exec rspec spec/lib/parse_name_spec.rb
require 'rails_helper'

describe 'Library: parse_name' do
  it "Test 'Kevin'.parse_name" do
    expect('Kevin'.parse_name).to eq({ prefix: '', firstname: 'Kevin', middlename: '', lastname: '', suffix: '' })
  end

  it "Test 'Kevin Neubert'.parse_name" do
    expect('Kevin Neubert'.parse_name).to eq({ prefix: '', firstname: 'Kevin', middlename: '', lastname: 'Neubert', suffix: '' })
  end

  it "Test 'Mr. Neubert'.parse_name" do
    expect('Mr. Neubert'.parse_name).to eq({ prefix: 'Mr.', firstname: '', middlename: '', lastname: 'Neubert', suffix: '' })
  end

  it "Test 'Mr. Kevin'.parse_name" do
    expect('Mr. Kevin'.parse_name).to eq({ prefix: 'Mr.', firstname: '', middlename: '', lastname: 'Kevin', suffix: '' })
  end

  it "Test 'Mr. Kevin Neubert'.parse_name" do
    expect('Mr. Kevin Neubert'.parse_name).to eq({ prefix: 'Mr.', firstname: 'Kevin', middlename: '', lastname: 'Neubert', suffix: '' })
  end

  it "Test 'Kevin Jr.'.parse_name" do
    expect('Kevin Jr.'.parse_name).to eq({ prefix: '', firstname: 'Kevin', middlename: '', lastname: '', suffix: 'Jr.' })
  end

  it "Test 'Kevin, Jr.'.parse_name" do
    expect('Kevin, Jr.'.parse_name).to eq({ prefix: '', firstname: 'Kevin', middlename: '', lastname: '', suffix: 'Jr.' })
  end

  it "Test 'Kevin Neubert Jr.'.parse_name" do
    expect('Kevin Neubert Jr.'.parse_name).to eq({ prefix: '', firstname: 'Kevin', middlename: '', lastname: 'Neubert', suffix: 'Jr.' })
  end

  it "Test 'Kevin Neubert, Jr.'.parse_name" do
    expect('Kevin Neubert, Jr.'.parse_name).to eq({ prefix: '', firstname: 'Kevin', middlename: '', lastname: 'Neubert', suffix: 'Jr.' })
  end

  it "Test 'Mr. Kevin Neubert Jr.'.parse_name" do
    expect('Mr. Kevin Neubert Jr.'.parse_name).to eq({ prefix: 'Mr.', firstname: 'Kevin', middlename: '', lastname: 'Neubert', suffix: 'Jr.' })
  end

  it "Test 'Mr. Kevin Neubert, Jr.'.parse_name" do
    expect('Mr. Kevin Neubert, Jr.'.parse_name).to eq({ prefix: 'Mr.', firstname: 'Kevin', middlename: '', lastname: 'Neubert', suffix: 'Jr.' })
  end

  it "Test 'Mr. & Mrs. Kevin Neubert'.parse_name" do
    expect('Mr. & Mrs. Kevin Neubert'.parse_name).to eq({ prefix: 'Mr. Mrs.', firstname: 'Kevin', middlename: '', lastname: 'Neubert', suffix: '' })
  end
end
