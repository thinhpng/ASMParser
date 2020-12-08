#!/usr/bin/perl

use warnings FATAL => 'all';
use feature qw(say);
use Tk;
use Tk::DirTree;
use Cwd;

my $top = new MainWindow;
$top->withdraw;

my $t = $top->Toplevel;
$t->title("Choose directory:");
my $ok = 0;
#$t->geometry("300x450+200+200");
my $f = $t->Frame->pack(-fill => "x", -side => "bottom");

my $curr_dir = "D:\\Escalation";
#my $curr_dir = Cwd::cwd();

my $d;
$d = $t->Scrolled('DirTree',
    -scrollbars => 'osoe',
    -width => 100,
    -height => 40,
    -selectmode => 'browse',
    -exportselection =>1,
    -browsecmd => sub { $curr_dir = shift },
    -command => sub { $ok = 1; },
)->pack(-fill => "both", -expand => 1);

$d->chdir($curr_dir);

$f->Button(-text => 'Ok',
    -command => sub { $ok = 1 })->pack(-side => 'left');
$f->Button(-text => 'Cancel',
    -command => sub { $ok = 1 })->pack(-side => 'left');

$f->waitVariable(\$ok);

if ($ok == 1) { warn "The resulting directory is '$curr_dir'\n"; }