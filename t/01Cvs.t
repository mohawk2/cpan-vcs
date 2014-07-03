#!perl
use strict;
use Test::More;
use IPC::Open3;

BEGIN {
  my $pid = eval { open3 undef, undef, undef, "cvs --version" };
  plan skip_all => '"cvs" execution failed.'
    if $@ or waitpid($pid, 0) != $pid or $?>>8 != 0;
}

use Cwd;
use File::Copy qw(cp);
use File::Temp;
use File::Path qw(mkpath);
my $td = File::Temp->newdir;

my $distribution = cwd();
my $repository = "$td/repository";
my $sandbox = "$td/sandbox";
my $base_url = "vcs://localhost/VCS::Cvs$sandbox/td";

BEGIN { use_ok('VCS') }
BEGIN { use_ok('VCS::File') }
BEGIN { use_ok('VCS::Dir') }

$ENV{CVSROOT} = $repository;
mkpath $sandbox, "$repository/td/dir", +{};

system <<EOF;
cd $repository
cvs init
EOF

cp($distribution.'/t/cvs_testfiles/td/dir/file,v_for_testing',$repository.'/td/dir/file,v');

system <<EOF;
cd $sandbox
cvs -Q co td
cd td/dir
cvs -Q tag mytag1 file
cvs -Q tag mytag2 file
cd ../..
EOF

my $f = VCS::File->new("$base_url/dir/file");
ok(defined $f,'VCS::File->new');

my $h = $f->tags();
is($h->{mytag1},'1.2','file tags 1');
is($h->{mytag2},'1.2','file tags 2');

my @versions = $f->versions;
ok(scalar(@versions),'versions');
my ($old, $new) = @versions;
is($old->version(),'1.1','old version');
is($new->version(),'1.2','new version');

like($new->date, qr/2001.11.13 04:10:29/, 'date');

is($new->author(),'user','author');

my $d = VCS::Dir->new("$base_url/dir");
ok (defined($d),'Dir');

my $th = $d->tags();
#warn("\n",Dumper($th),"\n");
ok (exists $th->{'mytag1'});
ok (exists $th->{'mytag1'}->{$sandbox.'/td/dir/file'});
is($th->{'mytag1'}->{$sandbox.'/td/dir/file'},'1.2');

my @c = $d->content;
is(scalar(@c),1,'content');
is($c[0]->url(),"$base_url/dir/file",'cotent url');

done_testing;
