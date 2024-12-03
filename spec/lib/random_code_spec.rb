# frozen_string_literal: true

require 'rails_helper'

describe 'RandomCode' do
  let(:random_string) { 'asdfasdfasdfasdfasdfasdfasdfas' }

  before do
    allow(SecureRandom).to receive(:alphanumeric).with(30).and_return(random_string)
    allow(SecureRandom).to receive(:alphanumeric).with(20).and_return(random_string[0, 20])
    allow(SecureRandom).to receive(:alphanumeric).with(6).and_return(random_string[0, 6])
  end

  describe 'create' do
    it 'should generate 6 chars by default' do
      expect(RandomCode.new.create.length).to eq(6)
    end

    it 'should create a 20 char string' do
      expect(RandomCode.new.create(20).length).to eq(20)
    end

    it 'should generate a random string' do
      expect(RandomCode.new.create(20)).to eq(random_string[0, 20])
    end
  end

  describe 'salt' do
    it 'should create a 20 char string by default' do
      expect(RandomCode.new.salt.length).to eq(20)
    end

    it 'should create a a random string' do
      expect(RandomCode.new.salt).to eq(random_string[0, 20])
    end

    it 'should create a 30 char string by default' do
      expect(RandomCode.new.salt(30).length).to eq(30)
    end

    it 'should create a 30 char random string' do
      expect(RandomCode.new.salt(30)).to eq(random_string)
    end
  end
end
