use strict;
use warnings;
use Test::More;
use IPC::Open3;
BEGIN {
  unless (-e 't/rcs_testfiles/dir/RCS/file,v_for_testing') {
    plan skip_all => 'file,v_for_testing does not exist.';
  }
  my $pid = eval { open3 undef, undef, undef, "co -V" };
  plan skip_all => '"co" execution failed.'
    if $@ or waitpid($pid, 0) != $pid or $?>>8 != 0;
}

use File::Copy qw(cp);
use File::Temp;
use File::Path qw(mkpath);
use URI::URL;
my $td = File::Temp->newdir;
my $base_url = "vcs://localhost/VCS::Rcs" . URI::URL->newlocal($td)->unix_path;

use_ok('VCS');

mkpath "$td/dir/RCS", +{};
cp('t/rcs_testfiles/dir/file',$td.'/dir');
cp('t/rcs_testfiles/dir/RCS/file,v_for_testing',$td.'/dir/RCS/file,v');
system <<EOF;
cd $td/dir
rcs -q -nmytag1: file
rcs -q -nmytag2: file
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
is($new->date(),'2001/11/13 04:10:29','date');
is($new->author(),'user','author');

my $d = VCS::Dir->new("$base_url/dir");
ok (defined($d),'Dir');

my @c = $d->content;
is(scalar(@c),1,'content');
is($c[0]->url(),"$base_url/dir/file",'content url');

done_testing;
