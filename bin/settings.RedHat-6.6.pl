$bits = `uname -m`;
if ($bits =~ /i686/) {
  $openssl_compiler = 'linux-elf';
} else {
  $openssl_compiler = 'linux-x86_64';
}

$libxml2292 = {
  'name'      => 'libxml2-2.9.2',
  'fetch'     => 'wget ftp://xmlsoft.org/libxml2/libxml2-2.9.2.tar.gz',
  'pkgsrc'    => $build_dir . '/tgzs/libxml2-2.9.2.tar.gz',
  'srcdir'    => "${src}/libxml2-2.9.2",
  'extract'   => 'gunzip -c  %PKGSRC% | tar xvf - ',
  'configure' => "make clean; ./configure --prefix=${prefix} LDFLAGS=-static-libgcc --without-python",
  'make'      => 'make',
  'install'   => 'make install',
  'env' => {
    'PATH'          => $pathmap {$platform_os} || '/bin:/usr/bin',
    'LIBXML_CFLAGS' => "-I${prefix}/libxml2",
    'LIBXML_LIBS'   => '-lxml2',
  },
};

unshift @packages, 'libxml2292',;

$openssl100r = {
  %{$openssl100r},
  'configure' => "make clean; ./Configure  -L${prefix}/lib -I${prefix}/include shared zlib-dynamic --prefix=${prefix} --openssldir=${prefix} ${openssl_compiler} -static-libgcc",
};

$ruby200p643 = {
  %{$ruby200p643},
  'configure' => "make clean; ./configure --disable-install-doc --prefix=${prefix} LDFLAGS=\'-static-libgcc -L${prefix}/lib -Wl,-rpath,${prefix}/lib \' CPPFLAGS=-I${prefix}/include",
};

$augeas110 = {
  %{$augeas110},
  'configure' => "make clean; ./configure --prefix=${prefix} CPPFLAGS=-I${prefix}/include LDFLAGS=\'-L${prefix}/lib -Wl,-rpath,${prefix}/lib\' CFLAGS=\'-static-libgcc -lncurses\'",
};
