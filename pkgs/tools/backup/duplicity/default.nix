{ stdenv, fetchurl, lib, python2Packages, librsync, ncftp, gnupg, rsync, makeWrapper
, withBackblazeB2 ? false, backblaze-b2
}:

python2Packages.buildPythonApplication rec {
  name = "duplicity-${version}";
  version = "0.7.15";

  src = fetchurl {
    url = "http://code.launchpad.net/duplicity/0.7-series/${version}/+download/${name}.tar.gz";
    sha256 = "0v0a8pmnaa8b634gh9kqzbr3f6971sxbjshl6sqfr11j84a7vgsh";
  };

  # Can be removed in 0.7.16: https://bugs.launchpad.net/duplicity/+bug/1733057
  patches = [ ./duplicity-collections.patch ];

  buildInputs = [ librsync makeWrapper python2Packages.wrapPython ];
  propagatedBuildInputs = with python2Packages; [
    boto cffi cryptography ecdsa enum idna pygobject3
    ipaddress fasteners paramiko pyasn1 pycrypto six
  ] ++ lib.optionals withBackblazeB2 [ backblaze-b2 ];
  checkInputs = with python2Packages; [ lockfile mock pexpect ];

  # lots of tests are failing, although we get a little further now with the bits in preCheck
  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/duplicity \
      --prefix PATH : "${stdenv.lib.makeBinPath [ gnupg ncftp rsync ]}"

    wrapPythonPrograms
  '';

  preCheck = ''
    patchShebangs testing

    substituteInPlace testing/__init__.py \
      --replace 'mkdir testfiles' 'mkdir -p testfiles'
  '';

  meta = with stdenv.lib; {
    description = "Encrypted bandwidth-efficient backup using the rsync algorithm";
    homepage = http://www.nongnu.org/duplicity;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ viric peti ];
    platforms = platforms.unix;
  };
}
