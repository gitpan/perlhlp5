#!/usr/bin/perl
# pod2rtf - convert pod format to rtf (for Winhelp compiler HCRTF)
#
# given to the public domain 1996 by Reini Urban,
#   <rurban@xarch.tu-graz.ac.at>
#   http://xarch.tu-graz.ac.at/~rurban/projects.html
#
# usage: pod2rtf [options] [podfiles]
#   will read the cwd and parse all files with .pod extension
#   if no arguments are given on the command line.
#   derived from Larry Wall's pod2html.pl
# options:
#  -base alternative helpfile basename
#  -hpj  create the hpj, build the help and delete rtf's on success
#  -hlp  create or use an existing hpj, build the help
#  -hc3  use hc.exe help compiler (v3.x) instead of hcrtf.exe v4.x
# pagebreak rationale:
#   This differs from the other pod converters:
#   A page break is only inserted after a =back on the next =head or
#   and every file begin.
#
# Translation:
# Bold     {\b text}
# Italic   {\i text}
# Code     {\f2\fs18 text}
# =back    \page
# PopupLink-To  {\ul link-text}{\v link-key}
# Link-To  {\uldb link-text}{\v link-key}
# Link-Def {\super #}{\footnote link-key}
#          {\super $}{\footnote link-text}
#          {\super K}{\footnote link-text}
#          {\super +}{\footnote +}
#
# ignore all the hc errors, it's simplier this way.
# =item
#
# pod2rtf.pl and perl5.hlp got the same revision numbers
#
# $Log: pod2rtf.pl $
# Revision 1.51  1999/12/26 19:00:11  rurban
#  - fixed top window
#  - fixed -hlp and -hpj, added -base
# Revision 1.5  1999/12/26 16:40:47  rurban
#  - based on perlpod 5.005_62 (ie 5.6) and pod2rtf 1.5
#  - fixed perlre pages:
#    the most important 2nd page was missing from 1.4
#  - added perlopentut, perlreftut, perltootc, perlthrtut, perldbmfilter,
#    perltodo, win32, perlcompile, perlhack
#  - fixed plain paragraphs
#  - fixed vernum
#  - added top window
#  - fixed -hlp and -hpj, added -base
# 1.4:  19.07.99
#  - new perl5 build based on the 5.005_02 pods
#    the former was based on 5.003 or 5.004 pods (don't know anymore)
#  - renamed from perl.hlp tp perl5.hlp
# 1.3:  15.12.96
#    -hlp, -hc3, build helpfiles automatically,
#    bugfix with .pm extensions
# 1.21: 07.12.96 18:09
#    appends my authors info even on not perl help files.
#    accepts .POD files too (befor only .pod)
# 1.2:  09.08.96
#    fixed some ugly bugs in perlvar
#    added the browsing footnote to pod2rtf.pl (will generate more errors,
#    but I still don't wanna check if the footnote is on the top of a
#    page or not. hc does it anyway.)
#    the help file this time is the automatic generated.
# 1.1:
#    added the HTML_Escape table, put it over to CPAN
#    the help file is the same as 1.0
# 1.0:
#    the help file was totally worked over,
#    and had almost nothing to do with the automatic generated rtf's.
#---------------------------------------------------------------
BEGIN {

%HTML_Escapes = (
    'amp'	=>	'&',	#   ampersand
    'lt'	=>	'<',	#   left chevron, less-than
    'gt'	=>	'>',	#   right chevron, greater-than
    'quot'	=>	'"',	#   double quote

    "Aacute"	=>  "\\\'e7",	#   capital A, acute accent
    "aacute"	=>  "\\\'87",	#   small a, acute accent
    "Acirc"     =>  "\\\'e5",   #   capital A, circumflex accent
    "acirc"     =>  "\\\'89",   #   small a, circumflex accent
    "AElig"     =>  '\\\'ae',   #   capital AE diphthong (ligature)
    "aelig"     =>  '\\\'be',   #   small ae diphthong (ligature)
    "Agrave"	=>  "\\\'cb",	#   capital A, grave accent
    "agrave"	=>  "\\\'88",	#   small a, grave accent
    "Aring"     =>  '\\\'81',   #   capital A, ring
    "aring"     =>  '\\\'8c',   #   small a, ring
    "Atilde"	=>  '\\\'cc',	#   capital A, tilde
    "atilde"	=>  '\\\'8b',	#   small a, tilde
    "Auml"      =>  '\\\'80',   #   capital A, dieresis or umlaut mark
    "auml"      =>  '\\\'8a',   #   small a, dieresis or umlaut mark
    "Ccedil"	=>  '\\\'82',	#   capital C, cedilla
    "ccedil"	=>  '\\\'8d',	#   small c, cedilla
    "Eacute"	=>  "\\\'83",	#   capital E, acute accent
    "eacute"	=>  "\\\'8e",	#   small e, acute accent
    "Ecirc"     =>  "\\\'e6",   #   capital E, circumflex accent
    "ecirc"     =>  "\\\'90",   #   small e, circumflex accent
    "Egrave"	=>  "\\\'e9",	#   capital E, grave accent
    "egrave"	=>  "\\\'8f",	#   small e, grave accent
    "Euml"      =>  "\\\'e8",   #   capital E, dieresis or umlaut mark
    "euml"      =>  "\\\'91",   #   small e, dieresis or umlaut mark
    "Iacute"	=>  "\\\'ea",	#   capital I, acute accent
    "iacute"	=>  "\\\'92",	#   small i, acute accent
    "Icirc"     =>  "\\\'eb",   #   capital I, circumflex accent
    "icirc"     =>  "\\\'90",   #   small i, circumflex accent
    "Igrave"	=>  "\\\'e9",	#   capital I, grave accent
    "igrave"	=>  "\\\'93",	#   small i, grave accent
    "Iuml"      =>  "\\\'ec",   #   capital I, dieresis or umlaut mark
    "iuml"      =>  "\\\'95",   #   small i, dieresis or umlaut mark
    "Ntilde"	=>  '\\\'84',	#   capital N, tilde
    "ntilde"	=>  '\\\'96',	#   small n, tilde
    "Oacute"	=>  "\\\'ee",	#   capital O, acute accent
    "oacute"	=>  "\\\'97",	#   small o, acute accent
    "Ocirc"     =>  "\\\'ef",   #   capital O, circumflex accent
    "ocirc"     =>  "\\\'99",   #   small o, circumflex accent
    "Ograve"	=>  "\\\'f1",	#   capital O, grave accent
    "ograve"	=>  "\\\'98",	#   small o, grave accent
    "Oslash"	=>  "\\\'af",	#   capital O, slash
    "oslash"	=>  "\\\'bf",	#   small o, slash
    "Otilde"	=>  "\\\'cd",	#   capital O, tilde
    "otilde"	=>  "\\\'9b",	#   small o, tilde
    "Ouml"      =>  "\\\'85",   #   capital O, dieresis or umlaut mark
    "ouml"      =>  "\\\'9a",   #   small o, dieresis or umlaut mark
    "Uacute"	=>  "\\\'f2",	#   capital U, acute accent
    "uacute"	=>  "\\\'9c",	#   small u, acute accent
    "Ucirc"     =>  "\\\'f3",   #   capital U, circumflex accent
    "ucirc"     =>  "\\\'9e",   #   small u, circumflex accent
    "Ugrave"	=>  "\\\'f4",	#   capital U, grave accent
    "ugrave"	=>  "\\\'9d",	#   small u, grave accent
    "Uuml"      =>  "\\\'86",   #   capital U, dieresis or umlaut mark
    "uuml"      =>  "\\\'9f",   #   small u, dieresis or umlaut mark
    "yuml"      =>  "\\\'d8",   #   small y, dieresis or umlaut mark
);
}

*RS = */;
*ERRNO = *!;

use Carp;
# use strict;
( $VERSION ) = '$Revision: 1.51 $ ' =~ /\$Revision:\s+([^\s]+)/;
$vernum = int($VERSION*100);
$gensym = 0;

while ($ARGV[0] =~ /^-d(.*)/) {
    shift;
    $Debug{ lc($1 || shift) }++;
}

$base++, shift if $ARGV[0] =~ /^-base$/;
$hpj++, shift if $ARGV[0] =~ /^-hpj$/;
$hlp++, shift if $ARGV[0] =~ /^-hlp$/;
$hc3++, shift if $ARGV[0] =~ /^-hc3$/;

# look in these pods for things not found within the current pod
@inclusions = qw[
     perlfunc perlvar perlrun perlop
];

# don't process these unless stated explicitly
@exclude = qw[
     perltoc
];


# ck for podnames on command line
while ($ARGV[0]) {
    push(@Pods,shift);
}
$A={};

# location of pods
$dir=".";
$debug = 0;

# rtf tokens
$type   ='{\uldb ';
$head   = '\b\f1\fs28 ';     # arial bold 14
$head1  = '\b\f1\fs28 ';     # arial bold 14
$head2  = '\b\i\f1\fs24 ';   # arial bold italic 12
$indent = '\li360\widctlpar';
$negfirst = '\tx360\li360\fi-360\widctlpar';  #indented but first line left
$bullet = $negfirst . '{\f3\\\'B7}\tab'; # symbol *
$codefont = '\f2\fs18';     # courier 9

unless(@Pods){
    opendir(DIR,$dir)  or  die "Can't opendir $dir: $ERRNO";
    @Pods = grep(/\.pod$/i, readdir(DIR));
    closedir(DIR) or die "Can't closedir $dir: $ERRNO";
    @Pods = grep(!/\.pod$/i, @exclude);
}
@Pods or die "expected pods";

# loop twice through the pods, first to learn the links, then to produce rtf
for $count (0,1){
    (print "pod2rtf.pl v$VERSION\nScanning pods...\n") unless $count;
    foreach $podfh ( @Pods ) {
        ($pod = $podfh) =~ s/\.pod$//i;
        Debug("files", "opening 2 $podfh" );
        (print "Creating $pod.rtf from $podfh\n") if $count;
        $RS = "\n=";
        open($podfh,"<".$podfh)  || die "can't open $podfh: $ERRNO";
        @all=<$podfh>;
        close($podfh);
        $RS = "\n";
        $all[0]=~s/^=//;
        for(@all){s/=$//;}
        $Podnames{$pod} = 1;
        $in_list=0;
        $rtf=$pod.".rtf";
        if($count){
            dumptable($A->{$pod}->{"Headers"}) if $Debug{"dump"};
            dumptable($A->{$pod}->{"Items"}) if $Debug{"dump"};
            for(@all){
                s/\\/\\\\/gm;
                s/{/\\{/gm;
                s/}/\\}/gm;
                }
            open(RTF,">$rtf") || die "can't create $rtf: $ERRNO";
#             <!-- \$RCSfile\$\$Revision\$\$Date\$ -->
#             <!-- \$Log\$ -->
            print RTF <<'RTF__EOQ';
{\rtf1\ansi \deff0\deflang1024

{\fonttbl
{\f0\froman Times New Roman;}
{\f1\fswiss Arial;}
{\f2\fmodern Courier New;}
{\f3\froman Symbol;}
}
{\colortbl;
\red0\green0\blue0;
\red0\green0\blue255;
\red0\green255\blue0;
\red255\green0\blue0;
\red255\green255\blue255;}
RTF__EOQ
            print RTF "{\\info{\\author Reini Urban / pod2rtf.pl}",
                      "{\\*\\company X-RAY}{\\vern$vernum}";
            ($sec,$min,$hr,$dy,$mo,$yr,@rest) = localtime();
            print RTF "{\\creatim\\yr$yr\\mo$mo\\dy$dy\\hr$hr\\min$min}}\n";
            print RTF '{',"\n",'{\b\f1\fs28\li120\sb340\sa120\sl-320';
            print RTF pageheader(def_name($pod,$pod));
            print RTF "}\n";
        }

        for($i=0;$i<=$#all;$i++){

            $all[$i] =~ /^(\w+)\s*(.*)\n?([^\0]*)$/ ;
            ($cmd, $title, $rest) = ($1,$2,$3);
            if ($cmd eq "item") {
                if($count ){
                    ($depth) or do_list("over",$all[$i],\$in_list,\$depth);
                    do_item($title,$rest,$in_list);
                }
                else{
                    # scan item
                    scan_thing("item",$title,$pod);
                }
            }
            elsif ($cmd =~ /^head([12])/){
                $num=$1;
                if($count){
                    do_hdr($num,$title,$rest,$depth);
                }
                else{
                    # header scan
                    scan_thing($cmd,$title,$pod); # skip head1
                }
            }
            elsif ($cmd =~ /^over/) {
                $count and $depth and do_list("over",$all[$i+1],\$in_list,\$depth);
            }
            elsif ($cmd =~ /^back/) {
                if($count){
                    ($depth) or next; # just skip it
                    do_list("back",$all[$i+1],\$in_list,\$depth);
                    do_rest("$title.$rest");
                }
            }
            elsif ($cmd =~ /^cut/) {
                next;
            }
            elsif($Debug){
                (warn "unrecognized header: $cmd") if $Debug;
            }
        }
        # close open lists without '=back' stmts
        if($count){
            while($depth){
                 do_list("back",$all[$i+1],\$in_list,\$depth);
            }
            # append my winhelp info to perl.rtf and win32.rtf
            if (grep(/perl/,@Pods)) {
                # append my winhelp info to perl.rtf and win32.rtf
                &author_info if $pod =~ /win32$/i || $pod =~ /^perl$/i;
            }
            else {
                # append it to the first found pod
                &author_info if $Pods[0] =~ /$pod\.pod/i;
            }
            # do author_info() if $pod =~ /^win32$/i || $pod =~ /^perl$/i;
            print RTF "\n} \n";
            close RTF;  # flush the buffer
        }
    }
    # print "execute 'hc perl' to compile the perl.hlp for Windows\n" if $count;
}

$base = $base or ($base = $Pods[0]) =~ s/\.\w*$//;
build_hpj ( $base ) if ($hpj or ($hlp and !-e $base . ".hpj"));
build_help( $base ) if $hlp || $hpj;

sub author_info{
    my ($s);
    #print RTF "\\par {$head1";
    #print RTF def_link("perl.hlp_author_info","perl.hlp for Windows NOTE");
    #print RTF "}\\page \n";
    print RTF "\\par\n";
    print RTF "{$head1\n";
    print RTF def_name("pod2rtf_author_info","PERL.HLP for Windows NOTE");
    print RTF "}\\par \n";
    $s = localtime();
    print RTF <<'RTF__A1';
{\pard \par
This windows help file was created by pod2rtf.pl by Reini Urban
<rurban@xarch.tu-graz.ac.at>
\par
pod {\uldb (plain old documentation)}{\v perlpod} is the simple
 documentation format of perl5, created by Larry Wall, which can be easily
 converted to HTML, RTF, manpages, ...\par
RTF files created by pod2rtf.pl are ready to be compiled with the Microsoft
 help compiler to Windows help files.\par
Get pod2rtf.pl at the CPAN archive under author RURBAN or at \par
 {\i ftp://xarch.tu-graz.ac.at/pub/autocad/urban/perl/}
RTF__A1

  print RTF "\\par \\pard created: $s with pod2rtf.pl v$VERSION\\par }";
}


sub do_list{
    my($which,$next_one,$list_type,$depth)=@_;
    my($key);
    if($which eq "over"){
        ($next_one =~ /^item\s+(.*)/ ) or (warn "Bad list, $1\n") if $Debug;
        $key=$1;
        if($key =~ /^1\.?/){
        $$list_type = "OL";
        }
        elsif($key =~ /\*\s*$/){
        $$list_type="UL";
        }
        elsif($key =~ /\*?\s*\w/){
        $$list_type="DL";
        }
        else{
        (warn "unknown list type for item $key") if $Debug;
        }
# 	 print RTF '\par ';
#        print RTF '{\li284\widctlpar ';
#        print RTF qq{<$$list_type>};
        $$depth++;
    }
    elsif($which eq "back"){
        # maybe we should wait for the next header and pagebreak there
        $pending_pagebreak = 1;
        # missing next, prev, up links
        $$depth--;
    }
}

sub do_hdr{
    my($num,$title,$rest,$depth)=@_;
    print RTF '\par';
    if ($pending_pagebreak) {
        print RTF '\page\keepn\par ',"{$head1 $pod - ";
        # print RTF pageheader($podname)
    }
    ($num == 1) and print RTF '\sln ';
    # def_link($title,"");
    process_thing(\$title,"NAME");
    if ($num==1) {
        print RTF " {$head1";
    } elsif ($num == 2) {
        print RTF " {$head2";
    } else {
        print RTF " {$head";
    }
    print RTF $title;
    if ($pending_pagebreak){
        print RTF '}\par';
        undef $pending_pagebreak;
    }
    print RTF '}\par \pard',"\n";
    do_rest($rest);
}

sub do_item{
    my($title,$rest,$list_type)=@_;
    $title =~ s/\*\s*/{\\f3\\'B7}\\tab /;
    process_thing(\$title,"NAME");
    if($list_type eq "DL"){
         print RTF "\n{\\b$negfirst";
         print RTF "$title";
         print RTF '}\par ';
         print RTF "{$indent ";
    }
    else{
        print RTF $bullet; #"{\\f3\\\'B7}\\tab";
        ($list_type ne "OL") && (print RTF $title,"\n");
    }
    do_rest($rest) if $rest ne "\n";
    print RTF ($list_type eq "DL" )? "}\n" : "\n";
}

sub do_rest{
    my($rest)=@_;
    my(@lines,$p,$q,$line,,@paras,$inpre);
    @paras=split(/\n\n+/,$rest);
    for($p=0;$p<=$#paras;$p++){
        @lines=split(/\n/,$paras[$p]);
        if($lines[0] =~ /^\s+\w*\t.*/){  # listing or unordered list
            print RTF "{$indent ";
            foreach $line (@lines){
                ($line =~ /^\s+(\w*)\t(.*)/) && (($key,$rem) = ($1,$2));
                print RTF defined($Podnames{$key}) ?
                    "\\par$bullet {\\uldb $key}{\\v $key}\\tab $rem\n" :
                    "\\par$bullet $line\n";
            }
            print RTF "}\n\\par";
        }
        elsif($lines[0] =~ /^\s/){       # preformatted code
            if($paras[$p] =~/>>|<</){
                print RTF "{$codefont ";
                $inpre=1;
            }
            else{
                print RTF "{$codefont ";
                $inpre=0;
            }
inner:
            while(defined($paras[$p])){
                @lines=split(/\n/,$paras[$p]);
                foreach $q (@lines){
                    if($paras[$p]=~/>>|<</){
                        if($inpre){
                            process_thing(\$q,"RTF");
                        }
                        else {
                            print RTF "\n}";
                            print RTF "\\par{$codefont ";
                            $inpre=1;
                            process_thing(\$q,"RTF");
                        }
                    }
                    while($q =~  s/\t+/' 'x (length($&) * 8 - length($`) % 8)/e){
                        1;
                    }
                    print RTF  $q,"\n\\par ";
                }
                last if $paras[$p+1] !~ /^\s/;
                $p++;
            }
            print RTF ($inpre==1) ? "\n} " : "\n} ";
        }
        else{                             # other text
            @lines=split(/\n/,$paras[$p]);
            foreach $line (@lines){
                process_thing(\$line,"RTF");
                print RTF "$line\n ";
            }
        }
        print RTF '\par ';
    }
}

# maybe include an upper navwindow
sub pageheader {
    my ($title,$prev,$next,$up) = @_;
    return "\n\\page\\keepn " .
           "{$head1\\tab $title " .
           # more links in the navwindow...
           "}\n\\par \\pard\n";
}

sub process_thing{
    my($thing,$htype)=@_;
    pre_escapes($thing);
    find_refs($thing,$htype);
    post_escapes($thing);
}

sub scan_thing{
    my($cmd,$title,$pod)=@_;
    $_=$title;
    s/\n$//;
    s/E<(.*?)>/isokey($1)/eg;
    # remove any formatting information for the headers
    s/[SFCBI]<(.*?)>/$1/g;
    # the "don't format me" thing
    s/Z<>//g;
    if ($cmd eq "item") {

        if (/^\*/)      {  return }     # skip bullets
        if (/^\d+\./)   {  return }     # skip numbers
        s/(-[a-z]).*/$1/i;
        trim($_);
        return if defined $A->{$pod}->{"Items"}->{$_};
        $A->{$pod}->{"Items"}->{$_} = gensym($pod, $_);
        $A->{$pod}->{"Items"}->{(split(' ',$_))[0]}=$A->{$pod}->{"Items"}->{$_};
        Debug("items", "item $_");
        if (!/^-\w$/ && /([%\$\@\w]+)/ && $1 ne $_
            && !defined($A->{$pod}->{"Items"}->{$_}) && ($_ ne $1))
        {
            $A->{$pod}->{"Items"}->{$1} = $A->{$pod}->{"Items"}->{$_};
            Debug("items", "item $1 REF TO $_");
        }
        if ( m{^(tr|y|s|m|q[qwx])/.*[^/]} ) {
            my $pf = $1 . '//';
            $pf .= "/" if $1 eq "tr" || $1 eq "y" || $1 eq "s";
            if ($pf ne $_) {
                $A->{$pod}->{"Items"}->{$pf} = $A->{$pod}->{"Items"}->{$_};
                Debug("items", "item $pf REF TO $_");
            }
        }
    }
    elsif ($cmd =~ /^head[12]/){
        return if defined($Headers{$_});
        $A->{$pod}->{"Headers"}->{$_} = gensym($pod, $_);
        Debug("headers", "header $_");
    }
    else {
        (warn "unrecognized header: $cmd") if $Debug;
    }
}

sub def_name {
    my ($value, $bigkey) = @_;
    if ($bigkey eq "") {  # guess the lost bigkey
        if (!defined ($bigkey = $A->{$podname}->{"Items"}->{$value})) {
            $value =~ /_/;
            $bigkey = uc($');
            $bigkey =~ s/^VAR_/\$/;
            $bigkey =~ s/^LIST_/\@/;
            $bigkey =~ s/_\d+?$//;
        }
        Debug("subs", "missed bigkey for $value, guessed: $bigkey\n");
    }
    return "\n{\\super \#{\\footnote \# $value}}\n".
		# a title should only appear after page breaks, but anyway
                "{\\super \${\\footnote \$ $bigkey}}\n".
                "{\\super K{\\footnote K $bigkey}}\n".
                # add also some browsing info, will force more errors,
                # but anyway. who cares?
                "{\\super +{\\footnote + xx}}\n".
                " $bigkey\n";
}
sub def_link {
    my ($value, $bigkey) = @_;
    if ($bigkey eq "") {  # guess the lost bigkey
        if (!defined ($bigkey = $A->{$podname}->{"Items"}->{$value})) {
            $value =~/_/;
            $bigkey = uc($');
            $bigkey =~ s/^VAR_/\$/;
            $bigkey =~ s/^LIST_/\@/;
            $bigkey =~ s/_\d+?$//;
        }
        Debug("subs", "missed bigkey for $value, guessed: $bigkey\n");
    }
    return "\n{\\uldb $bigkey}{\\v $value}";
}

sub picrefs {
    my($char, $bigkey, $lilkey,$htype) = @_;
    my ($key,$ref);
    for $podname ($pod,@inclusions){
        for $ref ( "Items", "Headers" ) {
            if (defined $A->{$podname}->{$ref}->{$bigkey}) {
                $value = $A->{$podname}->{$ref}->{$key=$bigkey};
                Debug("subs", "bigkey is $bigkey, value is $value\n");
            }
            elsif (defined $A->{$podname}->{$ref}->{$lilkey}) {
                $value = $A->{$podname}->{$ref}->{$key=$lilkey};
                return "" if $lilkey eq '';
                Debug("subs", "lilkey is $lilkey, value is $value\n");
            }
        }
        if (length($key)) {
            #($pod2,$num) = split(/_/,$value,2);
            if($htype eq "NAME"){
                return def_name($value, $bigkey);
            } else{
                return def_link($value, $bigkey);
            }
        }
    }
    if ($char =~ /[IF]/) {
        return "{\\i $bigkey} ";
    } elsif($char =~ /C/) {
        return "{$codefont $bigkey} ";
    } else {
        return "{\\b $bigkey} ";
    }
}

sub find_refs {
    my($thing,$htype)=@_;
    my($orig) = $$thing;
    # LREF: a manpage(3f) we don't know about
    $$thing=~s:L<([a-zA-Z][^\s\/]+)(\([^\)]+\))>:the I<$1>$2 section:g;
    $$thing=~s/L<([^>]*)>/lrefs($1,$htype)/ge;
    # somewhere here in these regex's is the nasty error with
    # the wrong bigkey's in perlvar
    $$thing=~s/([CIBF])<(\W*?(-?\w*).*?)>/picrefs($1, $2, $3, $htype)/ge;
    $$thing=~s/((\w+)\(\))/picrefs("I", $1, $2,$htype)/ge;
    $$thing=~s/([\$\@%](?!&[gl]t)([\w:]+|\W\b))/varrefs($1,$htype)/ge;
    (($$thing eq $orig) && ($htype eq "NAME")) &&
        ($$thing=picrefs("I", $$thing, "", $htype));
}

sub lrefs {
    my($page, $item) = split(m#/#, $_[0], 2);
    my($htype)=$_[1];
    # my($podname);
    my($section) = $page =~ /\((.*)\)/;
    my $selfref;
    if ($page =~ /^[A-Z]/ && $item) {
        $selfref++;
        $item = "$page/$item";
        $page = $pod;
    }  elsif (!$item && $page =~ /[^a-z\-]/ && $page !~ /^\$.$/) {
        $selfref++;
        $item = $page;
        $page = $pod;
    }
    $item =~ s/\(\)$//;
    if (!$item) {
        if (!defined $section && defined $Podnames{$page}) {
            return "\n\\par {\\uldb the {\\i $page} page}{\\v $page}\n";
        } else {
            (warn "Bizarre entry $page/$item") if $Debug;
            return "the {\\i $_[0]}  page\n";
        }
    }

    if ($item =~ s/"(.*)"/$1/ || ($item =~ /[^\w\/\-]/ && $item !~ /^\$.$/)) {
        $text = "{\\i $item} ";
        $ref = "Headers";
    } else {
        $text = "{\\i $item} ";
        $ref = "Items";
    }
    for $podname ($pod, @inclusions){
        undef $value;
        if ($ref eq "Items") {
            if (defined($value = $A->{$podname}->{$ref}->{$item})) {
                ($pod2,$num) = split(/_/,$value,2);
                return (($pod eq $pod2) && ($htype eq "NAME"))
                ? def_name($value, $item)
                : def_link($value, $item);
            }
        }
        elsif($ref eq "Headers") {
            if (defined($value = $A->{$podname}->{$ref}->{$item})) {
                ($pod2,$num) = split(/_/,$value,2);
                return (($pod eq $pod2) && ($htype eq "NAME"))
                ? def_name($value, $item)
                : def_link($value, $item);
            }
        }
    }
    (warn "No $ref reference for $item (@_)") if $Debug;
    return $text;
}

sub varrefs {
    my ($var,$htype) = @_;
    for $podname ($pod,@inclusions){
        if ($value = $A->{$podname}->{"Items"}->{$var}) {
            ($pod2,$num) = split(/_/,$value,2);
            Debug("vars", "way cool -- var ref on $var");
            return (($pod eq $pod2) && ($htype eq "NAME"))  # INHERIT $_, $pod
                ? def_name($value, $var)
                : def_link($value, $var);
        }
    }
    Debug( "vars", "bummer, $var not a var");
    return "{\\b $var} ";
}

# convert illegal names and characters for valid topic names
# $ -> VAR_
# @ -> LIST_
sub gensym {
    my($podname, $key) = @_;
    $key =~ s/\s.*/_/;         # trim whitespace to _
    $key =~ s/\$/VAR_/;        # $ARG -> VAR_ARG
    $key =~ s/\@/LIST_/;       # @ARG -> LIST_ARG
    ($key = lc($key)) =~ tr/a-z/_/cs;
    my $name = "${podname}_${key}_0";
    # $name =~ s/__/_/g;
    while ($sawsym{$name}++) {
        $name =~ s/_?(\d+)$/'_' . ($1 + 1)/e;
    }
    return $name;
}

sub pre_escapes {
    my($thing)=@_;
    $$thing=~s/(?:[^ESIBLCF])</noremap("<")/eg;
    $$thing=~s/\{/noremap("{")/eg;
    $$thing=~s/\}/noremap("}")/eg;
    $$thing=~s/\&/noremap("&")/eg;
    $$thing=~s/\%/noremap("%")/eg;
    $$thing=~s/\@/noremap("@")/eg;
    $$thing=~s/E<([^\/][^<>]*)>/isokey($1)/eg;              # embedded special
}

sub isokey {
    $char = $_[0];
    exists $HTML_Escapes{$char}
	? $char = $HTML_Escapes{$char}
	: $char =~ s/([0-9A-F][0-9A-F])/\\\'$1 /;
    $char;
}

sub noremap {
    my $hide = $_[0];
    $hide =~ tr/\000-\177/\200-\377/;
    $hide;
}

sub post_escapes {
    my($thing)=@_;
#    $$thing=~s/[^GM]>>/\&gt\;\&gt\;/g;
#    $$thing=~s/([^"MGAE])>/$1>/g;
    $$thing=~tr/\200-\377/\000-\177/;
}

sub Debug {
    my $level = shift;
    print STDERR @_,"\n" if $Debug{$level};
}

sub dumptable  {
    my $t = shift;
    print STDERR "TABLE DUMP $t\n";
    foreach $k (sort keys %$t) {
        printf STDERR "%-40s <%s>\n", $t->{$k}, $k;
    }
}
sub trim {
    for (@_) {
        s/^\s+//;
        s/\s\n?$//;
    }
}

# added with v1.3
sub build_hpj   #17.11.96 15:49, from aci2rtf.pl
{
    my ($base) = @_;
    $base =~ s/\.\w+$//;
    my ($windows,$hlp,$hpjout) = (1);

    $hlp      = $base . ".hlp";
    $hpjout   = $base . ".hpj";
    rename($hpjout, $hpjout . '.bak') if -f $hpjout;
    open(OUT, ">$hpjout") || die "can't create $hpjout: $ERRNO";
    print OUT <<'HPJ__OPT';
;This file is created automatically by pod2rtf.pl, changes will be lost!

[OPTIONS]
REPORT=Yes
HPJ__OPT
    if ( !$hc3 ) {
        print OUT "INDEX_SEPARATORS=\",\"\n";
        print OUT "HLP=$hlp\n",
                  "ERRORLOG=$base.err\n";
    }
    print OUT "TITLE=$base\n";
    print OUT "CONTENTS=$base\n";
    if (!$nocompress) {
        print OUT "COMPRESS=", ($hc3 ? "High\n" : "12 Hall Zeck\n");
    }
    if ( $windows ) {
        print OUT "\n[WINDOWS]\n";
        print OUT "main=\"$base\",(18,10,450,630)",
            ($hc3 ? ",0,,(192, 192, 192),0\n"
                  : ",60416,(r15663103),(r12632256)\n");
                  # : ",27904,,(r12632256)\n");
    }
    my @Rtfs = @Pods;
    map { $_ =~ s/\.\w+/\.rtf/ } @Rtfs;
    print OUT "\n[FILES]\n",
              join "\n", @Rtfs,
              <<'HPJ__REST';

[CONFIG]
BrowseButtons()
HPJ__REST

    close OUT;
    return $hpjout;
}   ##project

sub build_help  {    #15.12.96 19:40
    my ($out) = @_;
    my $base = $out;
    $base =~ s/\.\w+$//;
    my @err;

    if ($hc3) {
        print STDERR "\nhc $out";
        system "hc $out";
        print STDERR "\nwinhelp $base";
        system "winhelp $base";
    } else {
        print STDERR "\nhcrtf /xhn $out";
        system "hcrtf /xhn $out";
        # check for old compiler
        if (! -f $base . ".hlp") {
            print STDERR "\nError!\n";
            open (ERR,"<$base.err") &&
            do {
                @err = <ERR>;
                print @err;
                print STDERR "better try switch -hc3!" if grep (/HC6000/, @err);
                close ERR;
            }
        }
    }
}