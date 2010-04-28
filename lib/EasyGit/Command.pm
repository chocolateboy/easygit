package EasyGit::Command;

use EasyGit::Command::Common;

has name => (
    isa      => 'String',
    lazy     => 1,
    default  => sub { my $self = shift; my ($name) = ref($self) =~ /(\w+)$/; lc $name },
    required => 0,
);

# Our "see also" section in help usually references the same subsection
# as our class name. This is exported into template help pages e.g. command.tt
has git_equivalent => (
    isa      => 'String',
    required => 0,
    lazy     => 1,
    default  => sub { $_->name }
);

has git_repo_needed => (
    isa      => 'Boolean',
    required => 1,
    default  => 0,
);

sub BUILD {
  # We allow direct instantiation of the subcommand class only if they
  # provide a command name for us to pass to git.
  if (ref($class) eq "subcommand" && not(defined $self->{command})) {
    die "Invalid subcommand usage"
  }

  # Most commands must be run inside a git working directory
  if ($self->{git_repo_needed} || not(@ARGV > 0 && $ARGV[0] eq "--help")) {
    $self->{git_dir} = EasyGit::RepoUtil::git_dir();
    die "Must be run inside a git repository!\n" unless defined $self->{git_dir};
  }

  # Many commands do not work if no commit has yet been made
  if ($self->{initial_commit_error_msg} && EasyGit::RepoUtil::initial_commit() && (@ARGV < 1 || $ARGV[0] ne "--help")) {
    die "$self->{initial_commit_error_msg}\n";
  }

  return $self;
}

sub help {
  my $self = shift;
  my $package_name = $self->name;
  $package_name =~ s/_/-/; # Packages use underscores, commands use dashes

  my $git_equiv = $self->{git_equivalent};
  $git_equiv =~ s/_/-/;  # Packages use underscores, commands use dashes

  if ($package_name eq "subcommand") {
    exit EasyGit::ExecUtil::execute("$GIT_CMD $self->{command} --help")
  }

  $ENV{LESS} //= 'FRSX';

  my $less = ($USE_PAGER == 1) ? 'less' :
             ($USE_PAGER == 0) ? 'cat' :
             `$GIT_CMD config core.pager` || 'less';
  chomp($less);
  open(OUTPUT, "| $less") or die "can't open $less for output";
  print OUTPUT "$package_name: $COMMAND{$package_name}->{about}\n";
  print OUTPUT $self->{help};
  print OUTPUT "\nDifferences from git $package_name:";
  print OUTPUT "\n  None.\n" unless defined $self->{differences};
  print OUTPUT $self->{differences} if defined $self->{differences};
  if ($git_equiv) {
    print OUTPUT "\nSee also\n";
    print OUTPUT <<EOF;
  Run 'git help $git_equiv' for a comprehensive list of options available.
  eg $package_name is designed to accept the same options as git $git_equiv, and
  with the same meanings unless specified otherwise in the above
  "Differences" section.
EOF
  }
  close(OUTPUT);
  exit 0;
}

sub preprocess {
  my $self = shift;
  return if (@ARGV and $ARGV[0] eq '--');
  my $result = main::GetOptions('--help' => sub { $self->help() });
}

sub run {
  my $self = shift;
  my $package_name = ref($self);

  my $subcommand = $package_name eq "subcommand" ? $self->{'command'} : $package_name;

  @ARGV = Util::quote_args(@ARGV);
  return ExecUtil::execute("$GIT_CMD $subcommand @ARGV", ignore_ret => 1);
}

