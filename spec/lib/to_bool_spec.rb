require 'rails_helper'

describe 'Library: to_bool' do
  it 'Test "true".to_bool' do
    expect('true'.to_bool).to eq(true)
  end

  it 'Test "false".to_bool' do
    expect('false'.to_bool).to eq(false)
  end

  it 'Test "".to_bool' do
    expect(''.to_bool).to eq(false)
  end

  it 'Test "asdf".to_bool' do
    expect('asdf'.to_bool).to eq(false)
  end

  it 'Test -25.to_bool' do
    expect(-25.to_bool).to eq(false)
  end

  it 'Test 25.to_bool' do
    expect(25.to_bool).to eq(true)
  end

  it 'Test 0.to_bool' do
    expect(0.to_bool).to eq(false)
  end

  it 'Test 1.to_bool' do
    expect(1.to_bool).to eq(true)
  end

  it 'Test nil.to_bool' do
    expect(nil.to_bool).to eq(false)
  end

  it 'Test true.to_bool' do
    expect(true.to_bool).to eq(true)
  end

  it 'Test false.to_bool' do
    expect(false.to_bool).to eq(false)
  end
end
