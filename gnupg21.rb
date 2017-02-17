class Gnupg21 < Formula
  desc "GNU Privacy Guard: a free PGP replacement"
  homepage "https://www.gnupg.org/"
  url "https://gnupg.org/ftp/gcrypt/gnupg/gnupg-2.1.18.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/gnupg/gnupg-2.1.18.tar.bz2"
  sha256 "d04c6fab7e5562ce4b915b22020e34d4c1a256847690cf149842264fc7cef994"
  revision 1

  bottle do
    sha256 "92a72f415dfb309f8d8c432990b720c64d21529c8343105b35b7aeb538b94883" => :sierra
    sha256 "f4b7478d161580ab5e5c3cf0c5afa1d777e781625db13af2c0b12a1974058ce8" => :el_capitan
    sha256 "ec7db844d1ce34374b0217464f85ef41348174324c288a64ba394c759c002c6f" => :yosemite
  end

  option "with-gpgsplit", "Additionally install the gpgsplit utility"
  option "without-libusb", "Disable the internal CCID driver"
  option "without-test", "Don't verify the build with `make check`"

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

  # Remove for > 2.1.18
  # ssh-import.scm fails on Yosemite
  # Reported 7 Feb 2017 https://bugs.gnupg.org/gnupg/issue2947
  # https://git.gnupg.org/cgi-bin/gitweb.cgi?p=gnupg.git;a=patch;h=56aa85f88f6b35fb03a2dc1a95882d49a74290e3
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/ea1e9f8/gnupg21/ssh-import-scm.patch"
    sha256 "888bce2b16cb7acca6521bc242721f703678b4e6d19b89b578b467f8d669e4f0"
  end

  # Remove for > 2.1.18
  # "gnupg-2.1.18 fails to read a Yubikey Neo that gnupg-2.1.17 reads fine"
  # Upstream issue from 26 Jan 2017 https://bugs.gnupg.org/gnupg/issue2933
  patch do
    url "https://mirrors.ocf.berkeley.edu/debian/pool/main/g/gnupg2/gnupg2_2.1.18-6.debian.tar.bz2"
    mirror "https://mirrorservice.org/sites/ftp.debian.org/debian/pool/main/g/gnupg2/gnupg2_2.1.18-6.debian.tar.bz2"
    sha256 "fc8a74741a0383afcc8abef63a9449750c99051eb8b6e841e5aae62a2976969f"
    apply "patches/0028-scd-Backport-two-fixes-from-master.patch",
          "patches/0029-scd-Fix-use-case-of-PC-SC.patch"
  end

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
    system "make", "check"
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
