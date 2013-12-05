# watson-ruby [![Build Status](https://travis-ci.org/nhmood/watson-ruby.png?branch=master)](https://travis-ci.org/nhmood/watson-ruby)
### an inline issue manager
[watson](http://goosecode.com/watson) ([mirror](http://nhmood.github.io/watson-ruby)) is a tool for creating and tracking bug reports, issues, and internal notes in code.  
It is avaliable in two flavors, [watson-ruby](http://github.com/nhmood/watson-ruby) and [watson-perl](http://github.com/nhmood/watson-perl)

### See watson in action [here](http://goosecode.com/watson) ([mirror](http://nhmood.github.io/watson-ruby))
### See the RDoc documentation [here](http://goosecode.com/watson/ruby/doc/) ([mirror](http://nhmood.github.io/watson-ruby/ruby/doc/))

## Installation
watson-ruby has been tested with **Ruby v2.0.0p247** and **RubyGems v2.0.3** (on **Arch Linux**)  
watson-ruby requires the ```json``` gem

### From Repo
watson-ruby is avaliable as a RubyGems ([link](https://rubygems.org/gems/watson-ruby)).  
You can either download it directory from ```gem``` using
```
gem install watson-ruby
```

Or you can clone this repo and install with Rake
```
git clone https://github.com/nhmood/watson-ruby.git .
cd watson-ruby
bundle install
bundle exec rake
```

## Usage
For a quick idea of how to use watson, check out the [app demo](http://goosecode.com/watson)! ([mirror](http://nhmood.github.io/watson-ruby))  
See below for a description of what all the command line arguments do.  

### Supported Languages
If you see something missing from the list please either file an issue or  
submit a pull request (comment parsing happens in **lib/watson/paser.rb**)

- **C / C++**
- **Objective C**
- **C#**
- **Java**
- **Javascript**
- **PHP**
- **Go**
- **Scala**
- **Erlang**
- **Haskell**
- **Bash / Zsh**
- **Ruby**
- **Perl**
- **Python**
- **Coffeescript**
- **Clojure**

## Command line arguments
```
Usage: watson [OPTION]...
Running watson with no arguments will parse with settings in RC file
If no RC file exists, default RC file will be created

   -c, --context-depth   number of lines of context to provide with posted issue
   -d, --dirs            list of directories to search in
   -f, --files           list of files to search in
   --format              set output format for watson [print, json, unite, silent]
   -h, --help            print help
   -i, --ignore          list of files, directories, or types to ignore
   -p, --parse-depth     depth to recursively parse directories
   -r, --remote          list / create tokens for Bitbucket/GitHub
   -t, --tags            list of tags to search for
   -u, --update          update remote repos with current issues
   -v, --version         print watson version and info

Any number of files, tags, dirs, and ignores can be listed after flag
Ignored files should be space separated
To use *.filetype identifier, encapsulate in "" to avoid shell substitutions

Report bugs to: watson@goosecode.com
watson home page: <http://goosecode.com/projects/watson>
[goosecode] labs | 2012-2013

```
### All file/directory/tag related parameters support relative as well as absolute paths.

### -c, --context-lines [LINES]
This parameter specifies how many lines of context watson should include when posting issues to remote repos.  
When this parameter is set from the command line, the .watsonrc config file is written with the value; the command line option effectively sets the default value for this feature in the current directory.  
The default value is set to 15 (and can be found in the lib/watson/command.rb file).  


### -d, --dirs [DIRS]
This parameter specifies which directories watson should parse through.  
It should be followed by a space separated list of directories that should be parsed.  
If watson is run without this parameter, the current directory is parsed.  


### -f, --files [FILES]
This parameter specifies which files watson should parse through.  
It should be followed by a space separated list of files that should be parsed.  


### --format [PRINT, JSON, UNITE, SILENT]
This parameter specifies how watson should output the issues that it finds.  
If passed with `print`, the regular printing will occur, either to Unix less or STDOUT (depending on system).  
If passed with `json`, the output will be in the form of JSON, and will be stored in `.watsonresults`.  

- This particular option is useful if attempting to intergrate watson into other tools / platforms.

If passed with `unite`, the output will be compatible with the vim unite plugin (more details soon)  

If passed with `silent`, watson will have no output.  

- This particular option is useful if remote posting to GitHub or Bitbucket is desired without the visual component of watson.  
- For example, you could set up a **git commit hook** to post issues to GitHub/Bitbucket, but avoid the giant print out every time.


### -h, --help
This parameter displays the list of avaliable options for watson.  


### -i, --ignore [IGNORES]
This parameter specifies which files and directories watson should ignore when parsing.  
It should be followed by a space separated list of files and/or directories to be ignored.  
This parameter should be used as an opposite to -d/-f, when there are more files that should be parsed in a directory than should be ignored.  


### -p, --parse-depth [PARSE_DEPTH]
This parameter specifies how deep watson should recursively parse directories.  
The 'depth' is defined as how many levels deep from the top-most specified directory to parse.  
If individual directories are passed with the -d (--dirs) flag, each will be parsed PARSE_DEPTH layers, regardless of their depth from the current directory.  
If watson is run without this parameter, the parsing depth is unlimited and will search through all subdirectories found.  


### -r, --remote [GITHUB, BITBUCKET]
This parameter is used to both list currently established remotes as well as setup new ones.  
If passed without any options, the currently established remotes will be listed.  
If passed with a github or bitbucket argument, watson will proceed to ask some questions to set up the corresponding remote.  


### -s, --show [ALL, CLEAN, DIRTY]
This parameter is used to specify which types of files and entries are shown when watson is run.  
If passed with the `clean` argument, only files that watson did *NOT* find issues in will be displayed.  
If passed with the `dirty` argument, only files that watson *DID* find issues in will be displayed.  
If passed with the `all` argument, watson will display all files, regardless of their issue status.  
The default behavior of watson is the `all` option.  


### -t, --tags [TAGS]
This parameter is used to specify which tags watson should look for when parsing.  
The tag currently supports any regular character and number combination, no special (!@#$...) characters.  


### -u, --update
This parameter is used to update remote repos with new issues.  
watson **does not** post new issues by default therefore this parameter is required to push up to GitHub/Bitbucket.  
watson **does** pull issue status by default, therefore you will always be notified of resolved issues on GitHub/Bitbucket.  

### -v, --version
This parameter displays the current version of watson you are running.  


## .watsonrc
watson supports an RC file that allows for reusing commong settings without repeating command line arguments every time.  

The .watsonrc is placed in every directory that watson is run from as opposed to a unified file (in ~/.watsonrc for example). The thinking behind this is that each project may have a different set of folders to ignore, directories to search through, and tags to look for.  
For example, a C/C++ project might want to look in src/ and ignore obj/ whereas a Ruby project might want to look in lib/ and ignore assets/.  

The .watsonrc file is fairly straightforward...  
**[dirs]** - This is a newline separated list of directories to look in while parsing.  

**[tags]** - This is a newline separated list of tags to look for while parsing.  

**[ignore]** - This is a newline separated list of files / folders to ignore while parsing.    
This supports wildcard type selecting by providing .filename (no * required)  

**[context_depth]** - This value determines how many lines of context should be grabbed for each issue when posting to a remote.  

**[(github/bitbucket)]** - If a remote is established, the API key for the corresponding remote is stored here.  
Currently, OAuth has yet to be implemented for Bitbucket so the Bitbucket username is stored here.  

**[(github/bitbucket)_repo]** - The repo name / path is stored here.  

The remote related .watsonrc options shouldn't need to be edited manually, as they are automatically populated when the -r, --remote setup is called.  

## Special Thanks
Special thanks to [@samirahmed](http://github.com/samirahmed) for his super Ruby help and encouraging the Ruby port!  
Special thanks to [@eugenekolo](http://twitter.com/eugenekolo) [[email](eugenek@bu.edu)] for his super Perl help!  
Special thanks to [@crowell](http://github.com/crowell) for testing out watson-ruby!  

## FAQ
- **Why Ruby?**  
  I wanted to learn Ruby and this seemed like a pretty decent project.

- **Why is the Ruby version different from the Perl version?**  
  The Ruby version was developed after the Perl version was made. Because of this, it was a lot easier to add on features that were thought of while/after making the Perl version as the plumbing was still being setup.  
  With a combination of wanting to finish watson-ruby as well as laziness, some of the improvements that were added to watson-ruby *have yet* to be pulled back into watson-perl.  
  If you are interested in helping out or maintaining watson-perl let me know!
