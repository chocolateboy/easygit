package EasyGit::Command::Common;

use Mouse ();
use Method::Signatures::Simple;

sub import {
    Mouse->import;
    Method::Singantures::Simple->import;
}

1;
