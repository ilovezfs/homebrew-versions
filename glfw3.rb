class Glfw3 < Formula
  desc "Multi-platform library for OpenGL applications"
  homepage "http://www.glfw.org/"
  url "https://github.com/glfw/glfw/archive/3.2.tar.gz"
  sha256 "cb3aab46757981a39ae108e5207a1ecc4378e68949433a2b040ce2e17d8f6aa6"
  head "https://github.com/glfw/glfw.git"

  bottle do
    cellar :any
    sha256 "753dbb80f0202b991aa295902f6856b15519c099d46accddd85358e4d7260b63" => :el_capitan
    sha256 "28d8a548c506afc1be463a76e4022f4dc9a38677aa3e00d8710b8bc75b2697b8" => :yosemite
    sha256 "b4285762307f7acc1def7e07f4a4c68ad4f6c87b83f130b4716a80f8eea41fbe" => :mavericks
  end

  option :universal
  option "without-shared-library", "Build static library only (defaults to building dylib only)"
  option "with-examples", "Build examples"
  option "with-test", "Build test programs"

  depends_on "cmake" => :build

  deprecated_option "build-examples" => "with-examples"
  deprecated_option "static" => "without-shared-library"
  deprecated_option "build-tests" => "with-test"
  deprecated_option "with-tests" => "with-test"

  def install
    ENV.universal_binary if build.universal?

    args = std_cmake_args + %W[
      -DGLFW_USE_CHDIR=TRUE
      -DGLFW_USE_MENUBAR=TRUE
    ]
    args << "-DGLFW_BUILD_UNIVERSAL=TRUE" if build.universal?
    args << "-DBUILD_SHARED_LIBS=TRUE" if build.with? "shared-library"
    args << "-DGLFW_BUILD_EXAMPLES=TRUE" if build.with? "examples"
    args << "-DGLFW_BUILD_TESTS=TRUE" if build.with? "test"
    args << "."

    system "cmake", *args
    system "make", "install"
    libexec.install Dir["examples/*"] if build.with? "examples"
    libexec.install Dir["tests/*"] if build.with? "tests"
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #define GLFW_INCLUDE_GLU
      #include <GLFW/glfw3.h>
      #include <stdlib.h>
      int main()
      {
        if (!glfwInit())
          exit(EXIT_FAILURE);
        glfwTerminate();
        return 0;
      }
    EOS

    if build.with? "shared-library"
      system ENV.cc, "test.c", "-o", "test",
             "-I#{include}", "-L#{lib}", "-lglfw"
    else
      system ENV.cc, "test.c", "-o", "test",
             "-I#{include}", "-L#{lib}", "-lglfw3",
             "-framework", "IOKit",
             "-framework", "CoreVideo",
             "-framework", "AppKit"
    end
    system "./test"
  end
end
