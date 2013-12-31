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
      it 'return correct extension for c++' do
        @parser.get_comment_type('lib/watson.cpp').should eql ['//', '/*']
        @parser.get_comment_type('lib/watson.cc').should  eql ['//', '/*']
        @parser.get_comment_type('lib/watson.hpp').should eql ['//', '/*']
        @parser.get_comment_type('lib/watson.c').should   eql ['//', '/*']
        @parser.get_comment_type('lib/watson.h').should   eql ['//', '/*']
      end

      it 'return correct extension for java' do
        @parser.get_comment_type('lib/watson.java').should  eql ['//', '/*', '/**']
        @parser.get_comment_type('lib/watson.class').should eql ['//', '/*', '/**']
      end

      it 'return correct extension for csharp' do
        @parser.get_comment_type('lib/watson.cs').should  eql ['//', '/*']
      end

      it 'return correct extension for javascript' do
        @parser.get_comment_type('lib/watson.js').should  eql ['//', '/*']
      end

      it 'return correct extension for php' do
        @parser.get_comment_type('lib/watson.php').should  eql ['//', '/*', '#']
      end

      it 'return correct extension for objectivec' do
        @parser.get_comment_type('lib/watson.m').should   eql ['//', '/*']
        @parser.get_comment_type('lib/watson.mm').should  eql ['//', '/*']
      end

      it 'return correct extension for go' do
        @parser.get_comment_type('lib/watson.go').should  eql ['//', '/*']
      end

      it 'return correct extension for scala' do
        @parser.get_comment_type('lib/watson.scala').should  eql ['//', '/*']
      end

      it 'return correct extension for erlang' do
        @parser.get_comment_type('lib/watson.erl').should  eql ['%%', '%']
      end

      it 'return correct extension haskell' do
        @parser.get_comment_type('lib/watson.hs').should eql ['--']
      end

      it 'return correct extension bash' do
        @parser.get_comment_type('lib/watson.sh').should eql ['#']
      end

      it 'return correct extension ruby' do
        @parser.get_comment_type('lib/watson.rb').should eql ['#']
      end

      it 'return correct extension perl' do
        @parser.get_comment_type('lib/watson.pl').should eql ['#']
        @parser.get_comment_type('lib/watson.pm').should eql ['#']
        @parser.get_comment_type('lib/watson.t').should eql ['#']
      end

      it 'return correct extension python' do
        @parser.get_comment_type('lib/watson.py').should eql ['#']
      end

      it 'return correct extension coffeescript' do
        @parser.get_comment_type('lib/watson.coffee').should eql ['#']
      end

      it 'return correct extension zsh' do
        @parser.get_comment_type('lib/watson.zsh').should eql ['#']
      end

      it 'return correct extension (;; for clojure)' do
        @parser.get_comment_type('lib/watson.clj').should eql [';;']
      end

      it 'return correct extension handlebars' do
        @parser.get_comment_type('lib/watson.hbs').should eql ['{{!--']
      end

      it 'return correct extension jst handlebars' do
        @parser.get_comment_type('lib/watson.jst.hbs').should eql ['{{!--']
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
