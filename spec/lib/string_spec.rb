# spec/lib/string_spec.rb
# bundle exec rspec spec/lib/string_spec.rb
require 'rails_helper'

describe 'Library: string' do
  it "Test '1'.match_in_array(['1', '2', '3']" do
    expect('1'.match_in_array(%w[1 2 3])).to eq('1')
  end

  it "Test '5'.match_in_array(['1', '2', '3']" do
    expect('5'.match_in_array(%w[1 2 3])).to eq('')
  end

  it "Test '3'.match_in_array(['1', '2', '3']" do
    expect('3'.match_in_array(%w[1 2 3])).to eq('3')
  end

  it "Test '10'.match_in_array(['1', '2', '3', '10']" do
    expect('10'.match_in_array(%w[1 2 3 10])).to eq('10')
  end

  it "Test 'I like the number 10. Do you?'.match_in_array(['1', '2', '3', '10']" do
    expect('I like the number 10. Do you?'.match_in_array(%w[1 2 3 10])).to eq('10')
  end

  it "Test 'Y'.match_in_array(['y', 'n']" do
    expect('Y'.match_in_array(%w[y n])).to eq('y')
  end

  it "Test 'Y'.match_in_array(['Y', 'N']" do
    expect('Y'.match_in_array(%w[Y N])).to eq('Y')
  end

  it "Test 'This is the first day.'.match_in_array(['first', 'second']" do
    expect('This is the first day.'.match_in_array(%w[first second])).to eq('first')
  end

  it "Test 'This is the first day.'.match_in_array(['First', 'Second']" do
    expect('This is the first day.'.match_in_array(%w[First Second])).to eq('First')
  end

  it "Test 'This is the first day.'.match_in_array(['Second', 'Third']" do
    expect('This is the first day.'.match_in_array(%w[Second Third])).to eq('')
  end
end
