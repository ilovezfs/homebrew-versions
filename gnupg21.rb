class Gnupg21 < Formula
  desc "GNU Privacy Guard: a free PGP replacement"
  homepage "https://www.gnupg.org/"
  url "https://gnupg.org/ftp/gcrypt/gnupg/gnupg-2.1.15.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/gnupg/gnupg-2.1.15.tar.bz2"
  sha256 "c28c1a208f1b8ad63bdb6b88d252f6734ff4d33de6b54e38494b11d49e00ffdd"
  revision 1

  bottle do
    sha256 "c4d5d69e0eb0ec0b6afcb4c2c054d56be24777fca9c2236aa21086d52b441d2c" => :sierra
    sha256 "4d2e25993faf0ef71013fe8f9121a61fe85d7c37ab4be735b882d2b16f51672b" => :el_capitan
    sha256 "61426f161700e8992099742df3b905ba254403d6a8526ec3a40be4ffc73b37c1" => :yosemite
  end

  option "with-gpgsplit", "Additionally install the gpgsplit utility"
  option "with-test", "Verify the build with `make check`"

  depends_on "pkg-config" => :build
  depends_on "sqlite" => :build if MacOS.version == :mavericks
  depends_on "npth"
  depends_on "gnutls"
  depends_on "libgpg-error"
  depends_on "libgcrypt"
  depends_on "libksba"
  depends_on "libassuan"
  depends_on "pinentry"
  depends_on "gettext"
  depends_on "adns"
  depends_on "libusb-compat" => :recommended
  depends_on "readline" => :optional
  depends_on "homebrew/fuse/encfs" => :optional

  conflicts_with "gnupg2",
        :because => "GPG2.1.x is incompatible with the 2.0.x branch."
  conflicts_with "gpg-agent",
        :because => "GPG2.1.x ships an internal gpg-agent which it must use."
  conflicts_with "dirmngr",
        :because => "GPG2.1.x ships an internal dirmngr which it it must use."
  conflicts_with "fwknop",
        :because => "fwknop expects to use a `gpgme` with Homebrew/Homebrew's gnupg2."
  conflicts_with "gpgme",
        :because => "gpgme currently requires 1.x.x or 2.0.x."

  # Workaround for libgpg-error-1.25, which causes "Assertion failed: (res == 0)"
  # See https://lists.gnupg.org/pipermail/gnupg-devel/2016-November/032184.html
  # agent, dirmngr, scd: npth_init must be after fork.
  # https://git.gnupg.org/cgi-bin/gitweb.cgi?p=gnupg.git;a=commit;h=eda17649f8bd3b8ce7bfc00a3c11cbcae63c845d
  # Fix hang due to deferred thread initialization.
  # https://git.gnupg.org/cgi-bin/gitweb.cgi?p=gnupg.git;a=commit;h=d1ccab5176d7719328b287544b54b85e0277b146
  # agent, dirmngr, scd: Fix init_common_subsystems.
  # https://git.gnupg.org/cgi-bin/gitweb.cgi?p=gnupg.git;a=commit;h=fc0b392e766af8127094e8b529d25abb84ad1d65
  patch do
    url "https://gist.githubusercontent.com/ilovezfs/886cb0a52b0c51b8063ba95fde615d31/raw/cbbec3d6cdce1241f3656c8ebd73c14c5d060b7d/gistfile1.txt"
    sha256 "0423ac51346127d63bb568def8bfc16eb5e6ab64c40f0a76d88a8a4aaaec4368"
  end

  def install
    ENV.append "LDFLAGS", "-lresolv"
    ENV["gl_cv_absolute_stdint_h"] = "#{MacOS.sdk_path}/usr/include/stdint.h"

    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --sbindir=#{bin}
      --sysconfdir=#{etc}
      --enable-symcryptrun
      --with-pinentry-pgm=#{Formula["pinentry"].opt_bin}/pinentry
    ]

    args << "--with-readline=#{Formula["readline"].opt_prefix}" if build.with? "readline"

    # Adjust package name to fit our scheme of packaging both gnupg 1.x and
    # and 2.1.x and gpg-agent separately.
    inreplace "configure" do |s|
      s.gsub! "PACKAGE_NAME='gnupg'", "PACKAGE_NAME='gnupg2'"
      s.gsub! "PACKAGE_TARNAME='gnupg'", "PACKAGE_TARNAME='gnupg2'"
    end

    system "./configure", *args

    system "make"

    # intermittent "FAIL: gpgtar.scm" and "FAIL: ssh.scm"
    # https://bugs.gnupg.org/gnupg/issue2425
    system "make", "check" if build.with? "test"

    system "make", "install"

    bin.install "tools/gpgsplit" => "gpgsplit2" if build.with? "gpgsplit"

    # Move man files that conflict with 1.x.
    mv share/"doc/gnupg2/FAQ", share/"doc/gnupg2/FAQ21"
    mv share/"doc/gnupg2/examples/gpgconf.conf", share/"doc/gnupg2/examples/gpgconf21.conf"
    mv share/"info/gnupg.info", share/"info/gnupg21.info"
    mv man7/"gnupg.7", man7/"gnupg21.7"
  end

  def post_install
    (var/"run").mkpath
  end

  def caveats; <<-EOS.undent
    Once you run the new gpg2 binary you will find it incredibly
    difficult to go back to using `gnupg2` from Homebrew/Homebrew.
    The new 2.1.x moves to a new keychain format that can't be
    and won't be understood by the 2.0.x branch or lower.

    If you use this `gnupg21` formula for a while and decide
    you don't like it, you will lose the keys you've imported since.
    For this reason, we strongly advise that you make a backup
    of your `~/.gnupg` directory.

    For full details of the changes, please visit:
      https://www.gnupg.org/faq/whats-new-in-2.1.html

    If you are upgrading to gnupg21 from gnupg2 you should execute:
      `killall gpg-agent && gpg-agent --daemon`
    After install. See:
      https://github.com/Homebrew/homebrew-versions/issues/681
    EOS
  end

  test do
    system bin/"gpgconf"
  end
end
