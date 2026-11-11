class Aiw < Formula
  desc "Local full-text search and recap across your AI assistants"
  homepage "https://github.com/navjeetc/aiw"
  url "https://github.com/navjeetc/aiw/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "9809cfd8129ad64489678166898bbddeda3c86ef6bde9d8311f46c661025a891"
  license "MIT"

  # aiw is tested on Ruby 3.4; Homebrew's default ruby is 4.x.
  # sqlite3's build reads its bundled SQLite's flags through pkg-config. macOS runners happen to have it;
  # Linux build environments don't.
  depends_on "pkgconf" => :build
  depends_on "ruby@3.4"

  # sqlite3 compiles its bundled SQLite (with FTS5) and needs mini_portile2 to do it.
  resource "mini_portile2" do
    url "https://rubygems.org/gems/mini_portile2-2.8.9.gem"
    sha256 "0cd7c7f824e010c072e33f68bc02d85a00aeb6fce05bb4819c03dfd3c140c289"
  end

  resource "sqlite3" do
    url "https://rubygems.org/gems/sqlite3-2.9.6.gem"
    sha256 "956fe606956420d04ac7157d3ace620c8caba2135b2e05c76e483493da24d08e"
  end

  resource "rubyzip" do
    url "https://rubygems.org/gems/rubyzip-3.7.0.gem"
    sha256 "65c19294da75297a939006f3516deacc33185fbd721ff1954f7a231db6d3e121"
  end

  def install
    ruby = formula_opt_bin("ruby@3.4")
    gems = libexec/"vendor"
    ENV["GEM_HOME"] = gems
    ENV["GEM_PATH"] = gems

    resources.each do |r|
      system ruby/"gem", "install", r.cached_download, "--ignore-dependencies", "--no-document",
             "--install-dir", gems
    end
    # Build leftovers: sqlite3 links its SQLite statically, so the ~24MB compile tree isn't needed.
    rm_r [gems/"cache", *gems.glob("gems/sqlite3-*/{ext,ports}")]

    libexec.install "bin", "lib"
    (bin/"aiw").write_env_script libexec/"bin/aiw",
      PATH:     "#{ruby}:$PATH",
      GEM_HOME: gems,
      GEM_PATH: gems
  end

  test do
    # Catches a release tagged without bumping Aiw::VERSION.
    assert_equal "aiw #{version}\n", shell_output("#{bin}/aiw --version")

    ENV["HOME"] = testpath
    ENV["AIW_DB"] = testpath/"aiw.sqlite3"
    assert_match "Nothing imported yet", shell_output("#{bin}/aiw stats")

    # Importing creates the full-text index; searching it proves sqlite3 was built with FTS5.
    assert_match "0 imported", shell_output("#{bin}/aiw import")
    assert_match "No assistant conversations mention", shell_output("#{bin}/aiw --no-import nothing-here")
  end
end
