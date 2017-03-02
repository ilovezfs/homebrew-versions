class Gnupg21 < Formula
  desc "GNU Privacy Guard: a free PGP replacement"
  homepage "https://www.gnupg.org/"
  url "https://gnupg.org/ftp/gcrypt/gnupg/gnupg-2.1.19.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/gnupg/gnupg-2.1.19.tar.bz2"
  sha256 "46cced1f5641ce29cc28250f52fadf6e417e649b3bfdec49a5a0d0b22a639bf0"

  bottle do
    sha256 "1fda666df6abaf92e72ae74b06f18d1630857f882700867997af48613c8b036f" => :sierra
    sha256 "99d6bd60da26539a2b74146f5acda4f6d989ab9142a6146b95144d80bdb669bc" => :el_capitan
    sha256 "2321ce7e53dda227f74e6ce8391b1fb915f884b33b4b4f6a77086d8ea6fa2405" => :yosemite
  end

  option "with-gpgsplit", "Additionally install the gpgsplit utility"
  option "without-libusb", "Disable the internal CCID driver"
  option "with-test", "Verify the build with `make check`"

  deprecated_option "without-libusb-compat" => "without-libusb"

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
  depends_on "libusb" => :recommended
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

  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --sbindir=#{bin}
      --sysconfdir=#{etc}
      --enable-symcryptrun
      --with-pinentry-pgm=#{Formula["pinentry"].opt_bin}/pinentry
    ]

    args << "--disable-ccid-driver" if build.without? "libusb"
    args << "--with-readline=#{Formula["readline"].opt_prefix}" if build.with? "readline"

    # Adjust package name to fit our scheme of packaging both gnupg 1.x and
    # and 2.1.x and gpg-agent separately.
    inreplace "configure" do |s|
      s.gsub! "PACKAGE_NAME='gnupg'", "PACKAGE_NAME='gnupg2'"
      s.gsub! "PACKAGE_TARNAME='gnupg'", "PACKAGE_TARNAME='gnupg2'"
    end

    system "./configure", *args

    system "make"

    # Two upstream issues affect "make check" in 2.1.19:
    # 1. "make check" cannot run before "make install"
    # Reported 1 Mar 2017 https://bugs.gnupg.org/gnupg/issue2979
    # 2. ssh-import.scm fails during "make check"
    # Reported 1 Mar 2017 https://bugs.gnupg.org/gnupg/issue2980
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
