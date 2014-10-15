use strict;
use warnings;
use v5.10;
use Text::Template;
use File::Temp qw( tempdir );
use File::chdir;
use Path::Class::Dir;
use Path::Class::File;
use Getopt::Long qw( GetOptions );
use Data::GUID;

our $opt_appname     = 'appname ' . Data::GUID->new->as_string;
our $opt_orgname     = 'orgname';
our $opt_description = 'Empty Description';
our $opt_version     = '0.00';
our $opt_icon;
my $opt_setup;
my $opt_nsi;

GetOptions(
  "appname=s"     => \$opt_appname,
  "orgname=s"     => \$opt_orgname,
  "version=s"     => \$opt_version,
  "description=s" => \$opt_description,
  "setup=s"       => \$opt_setup,
  "nsi=s"         => \$opt_nsi,
  "icon=s"        => \$opt_icon,
);

if(defined $opt_icon)
{
  $opt_icon = Path::Class::File->new($opt_icon);
  $opt_icon = $opt_icon->absolute unless $opt_icon->is_absolute;
}

if(defined $opt_setup)
{
  $opt_setup = Path::Class::File->new($opt_setup);
  $opt_setup = $opt_setup->absolute unless $opt_setup->is_absolute;
}

my $tarball = shift @ARGV;

unless(defined $tarball)
{
  say STDERR "usage: $^X $0 tarball.tar.gz [ dir ]";
  exit 2;
}

unless(-r $tarball)
{
  say STDERR "$tarball not found / not readable";
}

my $dir = shift @ARGV;
$dir //= tempdir( CLEANUP => 1 );
$dir = Path::Class::Dir->new($dir);
$dir = $dir->absolute unless $dir->is_absolute;
$dir->mkpath(0, 0700) unless -d $dir;

$tarball = Path::Class::File->new($tarball);
$tarball = $tarball->absolute unless $tarball->is_absolute;

say "tarball = $tarball";
say "dir     = $dir";

sub run
{
  say "+ @_";
  system(@_);
  die "command failed" if $?;
}

my $save = $CWD;

say "+ cd $dir";
$CWD = $dir;
run 'tar', 'zxvf', $tarball;

($dir) = $dir->children;

say "+ cd $dir";
$CWD = $dir;
our $package_dir = $dir->basename;

if(defined $opt_icon)
{
  run 'cp', $opt_icon, 'icon.ico';
}

say '+ @@ scanning @@';

our @files;
our @dirs;
our $installsize = 0;

sub recurse {
  my $dir = shift;
  foreach my $child ($dir->children)
  {
    if($child->is_dir)
    {
      say "  dir  $child";
      push @dirs, $child;
      recurse($child);
    }
    else
    {
      say "  file $child";
      push @files, $child;
      $installsize += -s $child;
    }
  }
}

recurse(Path::Class::Dir->new);

($dir) = $dir->parent;
say "+ cd $dir";
$CWD = $dir;

say '+ @@ creating setup.nsi @@';
do {
  my $tmpl = Text::Template->new( TYPE => 'STRING', SOURCE => do { local $/; <DATA> }, DELIMITERS => [ '<<', '>>' ], PACKAGE => 'main' );
  my $text = $tmpl->fill_in;
  open my $fh, '>', 'setup.nsi';
  print $fh $text;
  close $fh;
};

run 'makensis', 'setup.nsi';

if(defined $opt_nsi)
{
  run 'cp', 'setup.nsi', $opt_nsi;
}

if(defined $opt_setup)
{
  run 'cp', 'setup.exe', $opt_setup;
}

$CWD = $save;

__DATA__

!define APPNAME "<< $opt_appname >>"
!define ORGNAME "<< $opt_orgname >>"
!define DESCRIPTION "<< $opt_description >>"
!define INSTALLSIZE "<< $installsize >>"

!define VERSION << $opt_version >>

RequestExecutionLevel admin

InstallDir "$PROGRAMFILES\${ORGNAME}\${APPNAME}"

<< -e "$package_dir/license.rtf" ? qq{LicenseData "$package_dir\\license.rtf"} : '' >>

Name "${ORGNAME} - ${APPNAME}"
<< $opt_icon ? qq{Icon "$package_dir\\icon.ico"} : '' >>
outFile "setup.exe"

!include LogicLib.nsh

<< -e "$package_dir/license.rtf" ? 'Page license' : '' >>
Page directory
Page instfiles

!macro VerifyUserIsAdmin
UserInfo::GetAccountType
pop $0
${If} $0 != "admin" ;Require admin rights on NT4+
  messageBox mb_iconstop "Administrator rights required!"
  setErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
quit
${EndIf}
!macroend

function .onInit
  setShellVarContext all
  !insertmacro VerifyUserIsAdmin
functionEnd

section "install"
  setOutPath $INSTDIR
  
  File /r << $package_dir >>\*.*
  writeUninstaller "$INSTDIR\uninstall.exe"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "DisplayName" "${ORGNAME} - ${APPNAME} - ${DESCRIPTION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
  << $opt_icon ? q{WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "DisplayIcon" "$\"$INSTDIR\icon.ico$\""} : '' >>
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "Publisher" "$\"${ORGNAME}$\""
  #WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "HelpLink" "$\"${HELPURL}$\""
  #WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "URLUpdateInfo" "$\"${UPDATEURL}$\""
  #WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "URLInfoAbout" "$\"${ABOUTURL}$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "DisplayVersion" "$\"${VERSION}.0$\""
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "VersionMajor" ${VERSION}
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "VersionMinor" "0"
  # There is no option for modifying or repairing the install
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "NoRepair" 1
  # Set the INSTALLSIZE constant (!defined at the top of this script) so Add/Remove Programs can accurately report the size
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}" "EstimatedSize" ${INSTALLSIZE}

sectionEnd

section un.onInit
  SetShellVarContext all
  MessageBox MB_OKCANCEL "Permanently remove ${APPNAME}?" IDOK next
    ABORT
  next:
  !insertmacro VerifyUserIsAdmin
sectionEnd

section "uninstall"
<<

  foreach my $file (map { $_->as_foreign('Win32') } @files) 
  {
    $OUT .= qq{  delete \$INSTDIR\\$file\n};
  }
  
  foreach my $dir (map { $_->as_foreign('Win32') } reverse @dirs)
  {
    $OUT .= qq{  rmDir \$INSTDIR\\$dir\n};
  }

>>
  delete $INSTDIR\uninstall.exe
  rmDir $INSTDIR
  
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ORGNAME} ${APPNAME}"
sectionEnd

