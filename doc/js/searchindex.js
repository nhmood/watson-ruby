var SearchIndex = 
[
	{
		"name": "Watson",
		"link": "Watson.html",
		"snippet": "",
		"type": "normalmodule"
	},
	{
		"name": "Watson::Command",
		"link": "Watson/Command.html",
		"snippet": "<p>Command line parser class Controls program flow and parses options given by\ncommand line\n",
		"type": "normalclass"
	},
	{
		"name": "Watson::Config",
		"link": "Watson/Config.html",
		"snippet": "<p>Configuration container class Contains all configuration options and state\nvariables that are accessed …\n",
		"type": "normalclass"
	},
	{
		"name": "Watson::FS",
		"link": "Watson/FS.html",
		"snippet": "<p>File system utility function class  Contains all methods for file access in\nwatson\n",
		"type": "normalclass"
	},
	{
		"name": "Watson::Parser",
		"link": "Watson/Parser.html",
		"snippet": "<p>Dir/File parser class Contains all necessary methods to parse through files\nand directories  for specified …\n",
		"type": "normalclass"
	},
	{
		"name": "Watson::Printer",
		"link": "Watson/Printer.html",
		"snippet": "<p>Printer class that handles all formatting and printing of parsed dir/file\nstructure\n",
		"type": "normalclass"
	},
	{
		"name": "Watson::Remote",
		"link": "Watson/Remote.html",
		"snippet": "<p>Remote class that handles all remote HTTP calls to Bitbucket and GitHub\n",
		"type": "normalclass"
	},
	{
		"name": "Watson::Remote::Bitbucket",
		"link": "Watson/Remote/Bitbucket.html",
		"snippet": "<p>Bitbucket remote access class Contains all necessary methods to obtain\naccess to, get issue list, and …\n",
		"type": "normalclass"
	},
	{
		"name": "Watson::Remote::GitHub",
		"link": "Watson/Remote/GitHub.html",
		"snippet": "<p>GitHub remote access class Contains all necessary methods to obtain access\nto, get issue list, and post …\n",
		"type": "normalclass"
	},
	{
		"name": "debug_print",
		"link": "Watson.html#method-i-debug_print",
		"snippet": "<p>Global debug print that prints based on local file DEBUG flag as well as\nGLOBAL debug flag\n",
		"type": "anymethod"
	},
	{
		"name": "check_less",
		"link": "Watson.html#method-i-check_less",
		"snippet": "<p>Perform system check to see if we are able to use unix less for printing\n",
		"type": "anymethod"
	},
	{
		"name": "execute",
		"link": "Watson/Command.html#method-c-execute",
		"snippet": "<p>Command line controller Manages program flow from given command line\narguments\n",
		"type": "anymethod"
	},
	{
		"name": "help",
		"link": "Watson/Command.html#method-c-help",
		"snippet": "<p>Print help for watson\n",
		"type": "anymethod"
	},
	{
		"name": "version",
		"link": "Watson/Command.html#method-c-version",
		"snippet": "<p>Print version information about watson\n",
		"type": "anymethod"
	},
	{
		"name": "set_context",
		"link": "Watson/Command.html#method-c-set_context",
		"snippet": "<p>set_context Set context_depth parameter in config\n",
		"type": "anymethod"
	},
	{
		"name": "set_dirs",
		"link": "Watson/Command.html#method-c-set_dirs",
		"snippet": "<p>set_dirs\n<p>Set directories to be parsed by watson\n",
		"type": "anymethod"
	},
	{
		"name": "set_files",
		"link": "Watson/Command.html#method-c-set_files",
		"snippet": "<p>set_files\n<p>Set files to be parsed by watson\n",
		"type": "anymethod"
	},
	{
		"name": "set_ignores",
		"link": "Watson/Command.html#method-c-set_ignores",
		"snippet": "<p>set_ignores Set files and dirs to be ignored when parsing by watson\n",
		"type": "anymethod"
	},
	{
		"name": "set_parse_depth",
		"link": "Watson/Command.html#method-c-set_parse_depth",
		"snippet": "<p>set_parse_depth  Set how deep to recursively parse directories\n",
		"type": "anymethod"
	},
	{
		"name": "set_tags",
		"link": "Watson/Command.html#method-c-set_tags",
		"snippet": "<p>set_tags Set tags to look for when parsing files and folders\n",
		"type": "anymethod"
	},
	{
		"name": "setup_remote",
		"link": "Watson/Command.html#method-c-setup_remote",
		"snippet": "<p>setup_remote Handle setup of remote issue posting for GitHub and Bitbucket\n",
		"type": "anymethod"
	},
	{
		"name": "new",
		"link": "Watson/Config.html#method-c-new",
		"snippet": "<p>Config initialization method to setup necessary parameters, states, and\nvars\n",
		"type": "anymethod"
	},
	{
		"name": "run",
		"link": "Watson/Config.html#method-i-run",
		"snippet": "<p>Parse through configuration and obtain remote info if necessary\n",
		"type": "anymethod"
	},
	{
		"name": "check_conf",
		"link": "Watson/Config.html#method-i-check_conf",
		"snippet": "<p>Check for config file in directory of execution Should have individual .rc\nfor each dir that watson is …\n",
		"type": "anymethod"
	},
	{
		"name": "create_conf",
		"link": "Watson/Config.html#method-i-create_conf",
		"snippet": "<p>Watson config creater Copies default config from /assets/defaultConf to the\ncurrent directory\n",
		"type": "anymethod"
	},
	{
		"name": "read_conf",
		"link": "Watson/Config.html#method-i-read_conf",
		"snippet": "<p>Read configuration file and populate Config container class\n",
		"type": "anymethod"
	},
	{
		"name": "update_conf",
		"link": "Watson/Config.html#method-i-update_conf",
		"snippet": "<p>Update config file with specified parameters Accepts input parameters that\nshould be updated and writes …\n",
		"type": "anymethod"
	},
	{
		"name": "check_file",
		"link": "Watson/FS.html#method-c-check_file",
		"snippet": "<p>Check if file exists and can be opened\n",
		"type": "anymethod"
	},
	{
		"name": "check_dir",
		"link": "Watson/FS.html#method-c-check_dir",
		"snippet": "<p>Check if directory exists and can be opened\n",
		"type": "anymethod"
	},
	{
		"name": "new",
		"link": "Watson/Parser.html#method-c-new",
		"snippet": "<p>Initialize the parser with the current watson config\n",
		"type": "anymethod"
	},
	{
		"name": "run",
		"link": "Watson/Parser.html#method-i-run",
		"snippet": "<p>Begins parsing of files / dirs specified in the initial dir/file lists\n",
		"type": "anymethod"
	},
	{
		"name": "parse_dir",
		"link": "Watson/Parser.html#method-i-parse_dir",
		"snippet": "<p>Parse through specified directory and find all subdirs and files\n",
		"type": "anymethod"
	},
	{
		"name": "parse_file",
		"link": "Watson/Parser.html#method-i-parse_file",
		"snippet": "<p>Parse through individual files looking for issue tags, then generate\nformatted issue hash\n",
		"type": "anymethod"
	},
	{
		"name": "get_comment_type",
		"link": "Watson/Parser.html#method-i-get_comment_type",
		"snippet": "<p>Get comment syntax for given file\n",
		"type": "anymethod"
	},
	{
		"name": "cprint",
		"link": "Watson/Printer.html#method-c-cprint",
		"snippet": "<p>Custom color print for static call (only writes to STDOUT)\n",
		"type": "anymethod"
	},
	{
		"name": "print_header",
		"link": "Watson/Printer.html#method-c-print_header",
		"snippet": "<p>Standard header print for static call (uses static cprint)\n",
		"type": "anymethod"
	},
	{
		"name": "print_status",
		"link": "Watson/Printer.html#method-c-print_status",
		"snippet": "<p>Status printer for static call (uses static cprint)  Print status block in\nstandard format\n",
		"type": "anymethod"
	},
	{
		"name": "new",
		"link": "Watson/Printer.html#method-c-new",
		"snippet": "<p>Printer initialization method to setup necessary parameters, states, and\nvars\n",
		"type": "anymethod"
	},
	{
		"name": "run",
		"link": "Watson/Printer.html#method-i-run",
		"snippet": "<p>Take parsed structure and print out in specified formatting\n",
		"type": "anymethod"
	},
	{
		"name": "cprint",
		"link": "Watson/Printer.html#method-i-cprint",
		"snippet": "<p>Custom color print for member call Allows not only for custom color\nprinting but writing to file vs  …\n",
		"type": "anymethod"
	},
	{
		"name": "print_header",
		"link": "Watson/Printer.html#method-i-print_header",
		"snippet": "<p>Standard header print for class call (uses member cprint)\n",
		"type": "anymethod"
	},
	{
		"name": "print_status",
		"link": "Watson/Printer.html#method-i-print_status",
		"snippet": "<p>Status printer for member call (uses member cprint) Print status block in\nstandard format\n",
		"type": "anymethod"
	},
	{
		"name": "print_structure",
		"link": "Watson/Printer.html#method-i-print_structure",
		"snippet": "<p>Go through all files and directories and call necessary printing methods\nPrint all individual entries, …\n",
		"type": "anymethod"
	},
	{
		"name": "print_entry",
		"link": "Watson/Printer.html#method-i-print_entry",
		"snippet": "<p>Individual entry printer Uses issue hash to format printed output\n",
		"type": "anymethod"
	},
	{
		"name": "http_call",
		"link": "Watson/Remote.html#method-c-http_call",
		"snippet": "<p>Generic HTTP call method Accepts input hash of options that dictate how the\nHTTP call is to be made\n",
		"type": "anymethod"
	},
	{
		"name": "setup",
		"link": "Watson/Remote/Bitbucket.html#method-c-setup",
		"snippet": "<p>Setup remote access to Bitbucket Get Username, Repo, and PW and perform\nnecessary HTTP calls to check …\n",
		"type": "anymethod"
	},
	{
		"name": "get_issues",
		"link": "Watson/Remote/Bitbucket.html#method-c-get_issues",
		"snippet": "<p>Get all remote Bitbucket issues and store into Config container class\n",
		"type": "anymethod"
	},
	{
		"name": "post_issue",
		"link": "Watson/Remote/Bitbucket.html#method-c-post_issue",
		"snippet": "<p>Post given issue to remote Bitbucket repo\n",
		"type": "anymethod"
	},
	{
		"name": "setup",
		"link": "Watson/Remote/GitHub.html#method-c-setup",
		"snippet": "<p>Setup remote access to GitHub  Get Username, Repo, and PW and perform\nnecessary HTTP calls to check validity …\n",
		"type": "anymethod"
	},
	{
		"name": "get_issues",
		"link": "Watson/Remote/GitHub.html#method-c-get_issues",
		"snippet": "<p>Get all remote GitHub issues and store into Config container class\n",
		"type": "anymethod"
	},
	{
		"name": "post_issue",
		"link": "Watson/Remote/GitHub.html#method-c-post_issue",
		"snippet": "<p>Post given issue to remote GitHub repo\n",
		"type": "anymethod"
	}
]
;
