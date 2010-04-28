use 5.010000;

use strict;
use warnings;

use inc::Module::Install;

name     'App-EasyGit';
author   'Elijah Newren';
license  'MIT';
all_from 'lib/App/EasyGit.pm';

requires 'IO::All'                     => '0.39';
requires 'IPC::Cmd';
requires 'IPC::System::Simple'         => '1.20';
requires 'List::MoreUtils'             => '0.22';
requires 'Method::Signatures::Simple'  => '0.05';
requires 'Mouse'                       => '0.49';
requires 'Path::Class'                 => '0.18';

requires 'File::ShareDir' => '1.01';
install_share 'help';

install_script 'bin/eg';
repository     'http://github.com/chocolateboy/easygit';

test_requires  'Test::Command' => '0.08';
test_requires  'Test::More';

WriteAll();
