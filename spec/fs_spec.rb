module Watson

require_relative 'helper_spec'

describe FS do
	before(:each) do
		silence_output
	end

	after(:each) do
		enable_output
	end

	describe '.check_file' do
		context 'blank input file' do
			it 'should return false' do
				FS.check_file('').should be_false
			end
		end

		context 'invalid input file' do
			it 'should return false' do
				FS.check_file('chickensoup.rb').should be_false
			end
		end

		context 'valid input file' do
			it 'should return true' do
				FS.check_file('spec/fs_spec.rb').should be_true
			end
		end
	end	

	describe '.check_dir' do
		context 'blank input dir' do
			it 'should return false' do
				FS.check_dir('').should be_false
			end
		end

		context 'invalid input dir' do
			it 'should return false' do
				FS.check_dir('./chickensoup').should be_false
			end
		end

		context 'valid input dir' do
			it 'should return true' do
				FS.check_dir('spec/').should be_true
			end
		end
	end

end

end
