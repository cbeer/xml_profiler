require 'rails_helper'

describe XmlProfiler::Indexer do
  describe '#initialize' do
    context 'with a string argument' do
      subject { described_class.new('<a />') }

      it 'is a nokogiri xml document' do
        expect(subject.doc).to be_a_kind_of Nokogiri::XML::Document
      end
    end

    context 'with an existing document' do
      let(:doc) { Nokogiri::XML('<a />') }
      subject { described_class.new(doc) }

      it 'is a nokogiri xml document' do
        expect(subject.doc).to eq doc
      end
    end
  end

  describe '#to_hash' do
    subject { described_class.new(doc) }
    context 'with a simple document' do
      let(:doc) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'simple.xml')) }

      it 'adds hierarchical elements' do
        expect(subject.to_hash).to include '/a[attr_1="1"]/b[attr_2="2"]/c/text()_tesim': array_including('c')
      end
    end

    context 'with a MODS document' do
      let(:doc) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'mods.xml')) }

      it 'counts the occurences of an element' do
        expect(subject.to_hash).to include 'count(/mods)_isim': 1
      end

      it 'counts the occurences of an attribute' do
        expect(subject.to_hash).to include 'count(/mods/@version)_isim': 1
      end

      it 'lists the children of an element' do
        expect(subject.to_hash).to include '/mods/*_ssim': array_including('@version', 'titleInfo')
        expect(subject.to_hash).not_to include '/mods/*_ssim': array_including('text')
      end

      it 'lists the values of an attribute' do
        expect(subject.to_hash).to include '/mods/@version_ssim': array_including('3.4')
      end

      it 'includes the text of an element' do
        expect(subject.to_hash).to include '/mods/originInfo/place/placeTerm[type="code"]/text()_tesim': array_including('fr')
      end
    end
  end
end
