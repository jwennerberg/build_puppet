#!/usr/bin/env perl

use Cwd qw/getcwd chdir/ ;
use Getopt::Long ;

chop ($hostname = `uname -n`) ;
chop ($arch = `uname -p`) ;

# Setup global varibales available later

$eis_puppet_version = '0.3.3' ;
my ($os, $rev) = (`uname -s`, `uname -r`) ;
chomp ($os, $rev) ;
if ($os eq 'Linux') {
    my $flavor = `uname -v` ;
    chomp ($flavor) ;
    if ($flavor =~ /-(Ubuntu)/) {
	$platform_os = "$1-$rev" ;
    } elsif ($flavor =~ /(RHEL)/i) {
	$platform_os = "$1-$rev" ;
    } else {
	$platform_os = "$flavor-$rev" ;
    }
} else {
    $platform_os = "$os-$rev" ;
}


my $arch = `uname -p` ;
chomp $arch ;
$platform_arch = $arch ;
$platform = "$platform_os-$platform_arch" ;
$src = 'src.' . $hostname ;
$top = getcwd ;
$prefix = '/opt/puppet' ;

# ---

sub logprint {
    print LOG @_ ;
}


sub packup {
    my $p = shift ;
    return if -d $p->{'srcdir'} ;
    chdir $src ;
    ($foo = $p->{'packup'}) =~ s/%([A-Z]+)%/$p->{lc $1}/eg ;
    open FOO, "-|", $foo || die 'Packup fail' ;
    while (defined <FOO>) {
	logprint $_ ;
    }
    close FOO ;
    if ($?) {
	print "packup returned $?) \n" ;
    }
    chdir $top ;
}

sub expand {
    my $ref = shift ;
    my $what = shift ;
    my $res ;

    ($res = $ref->{$what}) =~ s/%([A-Z]+)%/$ref->{lc $1}/eg ;
    return $res ;
}

sub build {
    my $p = shift ;
    
    chdir $p->{ 'srcdir' } ;
    
    while (($k, $v) = each %{$p->{ 'env' }}) {
	$remember {$k} = $v ;
	$ENV{$k} = $v ;
	logprint "setenv $k $v\n" ;
    }
    logprint "Configure: " . $p->{'configure'}, "\n" ;
    
    $cmd = expand ($p, 'configure') ;
    open CMD, "$cmd |" ;
    while (<CMD>) {
	logprint $_ ;
	print $_ if /fatal|error/i ;
    }
    close CMD ;

    logprint "make: " . $p->{'make'}, "\n" ;
    $cmd = expand ($p, 'make') ;
    open CMD, "$cmd |" ;
    while (<CMD>) {
	logprint $_ ;
	print $_ if /fatal|error/i ;
    }
    close CMD ;
    
    logprint "Install: " . $p->{'install'}, "\n" ;
    $cmd = expand ($p, 'install') ;
    open CMD, "$cmd |" ;
    while (<CMD>) {
	logprint $_ ;
	print $_ if /fatal|error/i ;
    }
    close CMD ;
    while (($k, $v) = each %remember) {
	$ENV{$k} = $v ;
    }
}

sub packit {

    # cleanup old files
    foreach (qw/prototype pkginfo postinstall/) {
	unlink "${prefix}/$_" ;
    }
    
    my @proto = `cd ${prefix} ; find . -print | pkgproto` ;

    #chop (my $name = `id -n -u`) ;
    #chop (my $group = `id -n -g`) ;
    my $id = `id -a` ;
    (my $name, $group) = ($id =~ m/\((\w+?)\).*?\((\w+)\)/) ;

    logprint $name, " ",  $group, "\n" ;

    grep ( { s/$name/bin/g ; s/$group/bin/g } @proto ) ;

    unshift @proto, ("d none /etc/puppet 0755 bin bin\n", 
		     "d none /opt/puppet 0755 bin bin\n",
		     "d none /var/lib/puppet 0755 bin bin\n") ;
    if ($postinstall) {
	unshift @proto, "i postinstall=./postinstall\n" ;
	open PI, "> ${prefix}/postinstall" ;
	print PI $postinstall ;
        close PI ;
    }
    unshift @proto, "i pkginfo=./pkginfo\n" ;
    open PROTO, "> ${prefix}/prototype" ;
    print PROTO @proto ;
    close PROTO ;

    open PKGINFO, "> ${prefix}/pkginfo" ;
    print PKGINFO join ("\n", @pkginfo) ;
    close PKGINFO ;

    system "cd ${prefix} ; pkgmk -o -r ${prefix}" ;
    system "cd /var/spool/pkg ; pkgtrans -s /var/spool/pkg ${target} EISpuppet" ;
}

sub debit {
    mkdir "${prefix}/DEBIAN", 0755 unless -d "${prefix}/DEBIAN" ;
    open CTRL, "> ${prefix}/DEBIAN/control" ;
    print CTRL join ("\n", @debinfo), "\n" ;
    close CTRL ;
}

sub fetch {
    my $p = shift ;
    my $cmd = $p->{'fetch'} ;
    chdir "${top}/tgzs" ;
    open FETCH, "-|", $cmd || die "Fetching " . $p->{'name'} . " failed" ;
    while (defined <FETCH>) {
	logprint $_ ;
    }
    close FETCH ;
    if ($?) {
	print "Fetch retval = $? \n" ;
    }
    chdir $top ;
}

# --- 

$dump = 0 ;
$err = 'ignore' ;
GetOptions (
    'top=s'      => \$top, 
    'error=s'    => \$err,
    'prefix=s'   => \$prefix,
    'packages=s' => \@pac,
    'dump'       => \$dump
    ) ;

mkdir "${top}/logs", 0755 unless -d "${top}/logs" ;
open LOG, ">", "$top/logs/build.$hostname-$$" ;

logprint "settings\n" ;
require "$top/bin/settings.pl" ;
if (-f "$top/bin/settings.$platform_os.pl") {
    logprint "$platform_os settings\n" ;
    print "$platform_os settings\n" ;
    require "$top/bin/settings.$platform_os.pl" ;
}
if (-f "$top/bin/settings.$hostname.pl") {
    logprint "$hostname settings\n" ;
    print "$hostname settings\n" ;
    require "$top/bin/settings.$hostname.pl" ;
}


@packages = split (/,/, join (',', @pac)) if @pac ;

print join (", ", @packages), "\n" ;
print "Platform_os = ${platform_os}\n" ;
if ($dump) {
    foreach $name (@packages) {
	$p = ${$name} ; 
        print $name, "\n" ;
        foreach (keys %{$p}) {    
	    print "\t$_ => $p->{$_} \n" ; # if ref \{$p->{$_}} eq 'SCALAR' ;
	    if (ref $p->{$_} eq 'HASH') {
		print "\t", $p->{$_}, "\n" ;
		while (($k, $v) = each %{$p->{$_}}) {
		    print "\t\t$k => $v \n" ;
		}
	    }
	}
    }
    exit 0 ;
}

chdir $top ;
mkdir 'tgzs', 0755 unless -d 'tgzs' ;
mkdir 'packages', 0755 unless -d 'packages' ;
mkdir $src, 0755 unless -d $src ;
foreach $name (@packages) {
    $_ = ${$name} ;
    logprint $_->{'name'}, "\n" ;
    print $_->{'name'}, "\n" ;
    fetch ($_) unless -f $_->{'pkgsrc'} ;
    packup ($_) unless -d $_->{'srcdir'} ;
    chdir $_->{'srcdir'} ;
    build ($_) ;
    chdir $top ;
}

if ($platform_os =~ /SunOS/) {
    packit () ;
} elsif ($platorm_os =~ /Ubuntu/) {
    debit () ;
} else {
    rpmit () ;
}