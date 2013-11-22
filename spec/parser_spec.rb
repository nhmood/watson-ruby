module Watson
require_relative 'helper_spec'

describe Parser do
  before(:each) do
    @config = Config.new
    @config.run
    @parser = Parser.new(@config)
    silence_output
  end

  after(:each) do
    @file = @config.instance_variable_get(:@rc_file)
    File.delete(@file) if File.exists?(@file)
    enable_output
  end


  describe '#get_comment_type' do
    context 'known extension' do
      it 'return correct extension (# for ruby)' do
        @parser.get_comment_type('lib/watson.rb').should eql '#'
      end

      it 'return correct extension (# for coffee)' do
        @parser.get_comment_type('lib/watson.coffee').should eql '#'
      end

      it 'return correct extension (// for c/c++)' do
        @parser.get_comment_type('lib/watson.cpp').should eql '//'
      end
    end

    context 'unknown extension' do
      it 'return false for unknown extension' do
        @parser.get_comment_type('lib/chickensoup').should be_false
      end
    end
  end

  describe '#parse_file' do
    context 'invalid file parse' do
      it 'return false on empty file input' do
        @parser.parse_file('').should be_false
      end
    end

    context 'blank file parse' do
      before do
        FileUtils.mkdir('test_dir')
        FileUtils.touch('test_dir/test_file')
      end

      it 'generate (blank) hash structure' do
        @structure = @parser.parse_file('test_dir/test_file')

        @structure[:relative_path].should == 'test_dir/test_file'
        @structure[:has_issues].should be_false

        @structure['fix'].should == []
        @structure['review'].should == []
        @structure['todo'].should == []
      end

      after do
        FileUtils.rm_rf('test_dir')
      end
    end

    context 'valid file parse' do
      before do
        FileUtils.mkdir('test_dir')
        FileUtils.cp('assets/examples/main.cpp', 'test_dir/')
      end

      it 'generate populated hash structure from file' do
        @structure = @parser.parse_file('test_dir/main.cpp')

        @structure[:relative_path].should == 'test_dir/main.cpp'
        @structure[:has_issues].should be_true
        @structure['fix'][0][:line_number].should == 16
      end

      after do
        FileUtils.rm_rf('test_dir')
      end
    end

  end

  describe '#parse_dir' do
    context 'empty dir parsing' do
      before do
        FileUtils.mkdir('test_dir')
      end

      it 'generate (blank) hash stucture' do
        @structure = @parser.parse_dir('test_dir/', 0)

        @structure[:curdir].should == 'test_dir/'
        @structure[:files].should == []
        @structure[:subdirs].should == []
      end

      after do
        FileUtils.rm_rf('test_dir')
      end
    end

    context 'single file in dir parsing' do
      before do
        FileUtils.mkdir('test_dir')
        FileUtils.cp('assets/examples/main.cpp', 'test_dir/')
      end

      it 'generate hash structure with parsed file' do
        @structure = @parser.parse_dir('test_dir/', 0)
        @structure[:files][0][:relative_path].should == 'test_dir/main.cpp'
        @structure[:files][0][:has_issues].should be_true
        @structure[:files][0]["fix"][0][:line_number].should == 16
      end

      after do
        FileUtils.rm_rf('test_dir')
      end
    end

  end

end

end
