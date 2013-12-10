module Watson
require_relative 'helper_spec'

describe Config do
  before(:each) do
    @config = Config.new
    @file = @config.instance_variable_get(:@rc_file)
    silence_output
  end

  after(:each) do
    File.delete(@file) if File.exists?(@file)
    enable_output
  end


  describe '#create_conf' do
    it 'create config file, return true' do
      @config.create_conf.should be_true
      File.exists?(@file).should be_true
    end
  end

  describe '#check_conf' do
    context 'config does not exist' do
      it 'create config file, return true' do
        @config.check_conf.should be_true
        File.exists?(@file).should be_true
      end
    end

    context 'config does exist' do
      it 'should return true' do
        @config.check_conf.should be_true
        File.exists?(@file).should be_true
      end
    end
  end

  describe '#read_conf' do
    context 'config does not exist' do
      it 'no config, return false' do
        @config.read_conf.should be_false
      end
    end

    context 'config does exist' do
      before { @config.create_conf }

      it 'return true, values match default config' do
        @config.create_conf.should be_true
        @config.read_conf.should be_true
        @config.dir_list.should include('.')
        @config.tag_list.should include('fix', 'review', 'todo')
        @config.ignore_list.should include('.git', '*.swp')

      end
    end
  end

  describe '#update_conf' do
    before do
      @config.check_conf
      @config.parse_depth = 1000
      @config.update_conf('parse_depth')
    end

    it 'updated config.parse_depth should be 1000' do
      @new_config = Config.new
      @new_config.check_conf.should be_true
      @new_config.read_conf.should be_true
      @new_config.parse_depth.to_i.should eql 1000
    end
  end

  # [review] - Should this be #initialize or #new?
  describe '#initialize' do
    it 'should initialize all member vars' do
      @config.cl_entry_set.should be_false
      @config.cl_tag_set.should be_false
      @config.cl_ignore_set.should be_false

      @config.use_less.should be_false

      @config.ignore_list.should == []
      @config.dir_list.should == []
      @config.file_list.should == []
      @config.tag_list.should == []

      @config.remote_valid.should be_false

      @config.github_valid.should be_false
      @config.github_api.should == ''
      @config.github_repo.should == ''
      @config.github_issues.should == {:open => Array.new(),
                                       :closed => Array.new() }

      @config.bitbucket_valid.should be_false
      @config.bitbucket_api.should == ''
      @config.bitbucket_repo.should == ''
      @config.bitbucket_issues.should == {:open => Array.new(),
                                          :closed => Array.new() }

    end
  end

  describe '#run' do
    it 'should populate all member vars' do
      @config.run
      @config.ignore_list.should include('.git', '*.swp')
      @config.tag_list.should include('fix', 'review', 'todo')
      @config.dir_list.should include('.')
    end

  end

end

end
