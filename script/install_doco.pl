use strict;
use warnings;
use v5.10;
use Path::Class::Dir;
use Path::Class::File;

my $prefix = Path::Class::Dir->new(pop @ARGV);

foreach my $file (map { Path::Class::File->new($_) } @ARGV)
{
  die "$file not found" unless -e $file;
  my $dest = $prefix->file($file->basename . '.txt');
  say "process $file => $dest";
  my $content = $file->slurp;
  $dest->spew(iomode => '>:crlf', $content);
  
  if($file->basename =~ /license|copying/i)
  {
  
    my $dest = $prefix->file('license.rtf');
    
    say "process $file => $dest";

    my @rtf = map { "$_\n" } (
      "{\\rtf\\ansi\\deff0",
      "{\\fonttbl{\\f0\\fswiss Courier New;}}",
      "\\paperw12240\\paperh15840\\margl504\\margr504\\margt504\\margb504",
      "\\fs14 ",
      (map { "$_\n\\line\n" } split(/\n/, $content =~ s{([\\{}])}{\\$1}gr =~ s{\f}{\n\\page\n}gr)),
      "}",
    );
    
    $dest->spew(iomode => '>:crlf', \@rtf);
  
  }
}
