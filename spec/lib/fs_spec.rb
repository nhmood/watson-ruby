require 'spec_helper'

module Watson
  describe FS do
    before do
      silence_output
    end

    after do
      enable_output
    end

    describe '.check_file' do
      subject { FS.check_file(file_path) }

      context 'given blank input file' do
        let(:file_path) { '' }
        it { should be_false }
      end

      context 'given invalid input file' do
        let(:file_path) { 'chickensoup.rb' }
        it { should be_false }
      end

      context 'given valid input file' do
        let(:file_path) { __FILE__ }
        it { should be_true }
      end
    end

    describe '.check_directory' do
      subject { FS.check_dir(directory) }

      context 'given blank input directory' do
        let(:directory) { '' }
        it { should be_false }
      end

      context 'given invalid input directory' do
        let(:directory) { './chickensoup' }
        it { should be_false }
      end

      context 'given valid input directory' do
        let(:directory) { 'spec/' }
        it { should be_true }
      end
    end
  end
end
