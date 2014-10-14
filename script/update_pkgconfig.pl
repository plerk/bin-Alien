use strict;
use warnings;
use v5.10;
use Path::Class::Dir;

my $prefix = shift @ARGV;

unless(defined $prefix)
{
  say STDERR "usage $^X $0 dir";
  exit 2;
}

$prefix = Path::Class::Dir->new($prefix);
$prefix = $prefix->absolute unless $prefix->is_absolute;

my $dir = $prefix->subdir('lib', 'pkgconfig');

my $rel = '${pcfiledir}/../..';

foreach my $child ($dir->children)
{
  next unless $child->basename =~ /\.pc$/;
  say $child->basename;
  my $content = $child->slurp;
  $content =~ s{$prefix}{$rel}g;
  $child->spew($content);
}
