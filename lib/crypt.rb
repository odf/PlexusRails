# ---------------------------------------------------------------------
# Slightly modified version of Guillaume Pierronnet's Ruby port of
# Poul-Henning Kamp's MD5-based one-way password hashing scheme.
#
# - replaced positional parameters by an option hash
# - introduced a strength variable and changed iteration count from
#   1000 to 10**strength
# - ported to Ruby 1.9.2
#
# Olaf Delgado-Friedrichs, 2007-10-12 / 2010-09-06
# ---------------------------------------------------------------------

# Crypt(3) 
# Version 0.2.0 2005-09-28 

# adapted by guillaume__dot__pierronnet_at__laposte__dot_net
# based on http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/325204/index_txt
# which is based on FreeBSD src/lib/libcrypt/crypt.c 1.2
# http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/src/lib/libcrypt/crypt.c?rev=1.2&content-type=text/plain

# Original license:
# * "THE BEER-WARE LICENSE" (Revision 42):
# * <phk@login.dknet.dk> wrote this file.  As long as you retain this notice you
# * can do whatever you want with this stuff. If we meet some day, and you think
# * this stuff is worth it, you can buy me a beer in return.   Poul-Henning Kamp

# This port adds no further stipulations.  I forfeit any copyright interest.

module Crypt
  
  ITOA64 = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  
  DEFAULT_ALGO = :md5
  DEFAULT_SALT = nil
  DEFAULT_STRENGTH = 3
  DEFAULT_MAGIC = '$1$'
  
  # an pure ruby version of crypt(3), a salted one-way hashing of a password 
  # 
  # supported hashing algorithms are: md5, sha1, sha256, sha384, sha512, rmd160
  # 
  # only the md5 hashing algorithm is standard and compatible with crypt(3), the others
  # are not standard.
  # 
  # automatically generate a 8-bytes salt if nil
  #
  # output a length hashed and salted string with size of
  # magic.size + salt.size + 23
  
  def self.crypt(password, options = {})
    algo = options[:algo] || DEFAULT_ALGO
    salt = options[:salt] || DEFAULT_SALT
    strength = options[:strength] || DEFAULT_STRENGTH
    magic = options[:magic] || DEFAULT_MAGIC
    
    salt ||= generate_salt(8)
    
    case algo
    when :md5, :sha1, :rmd160
      require "digest/#{algo}"
    when :sha256, :sha384, :sha512
      require "digest/sha2"
    else
      raise(ArgumentError, "unknown algorithm")
    end
    digest_class = Digest.const_get(algo.to_s.upcase)
    
    # The password first, since that is what is most unknown. Then our magic string. Then the raw salt.
    m = digest_class.new
    m.update(password + magic + salt)
    
    # Then just as many characters of the MD5(pw,salt,pw)
    mixin = digest_class.new.update(password + salt + password).digest
    password.length.times do |i|
      m.update(mixin[i % 16].chr)
    end
    
    # Then something really weird...
    # Also really broken, as far as I can tell.  -m
    i = password.length
    while i != 0
      if (i & 1) != 0
        m.update("\x00")
      else
        m.update(password[0].chr)
      end
      i >>= 1
    end
    
    final = m.digest
    
    # and now, just to make sure things don't run too fast
    (10**strength).times do |j|
      m2 = digest_class.new
      
      if (j & 1) != 0 
        m2.update(password) 
      else
        m2.update(final)
      end
      
      if (j % 3) != 0 
        m2.update(salt)
      end
      if (j % 7) != 0 
        m2.update(password) 
      end
      
      if (j & 1) != 0 
        m2.update(final) 
      else
        m2.update(password)
      end
      
      final = m2.digest
    end
    
    # This is the bit that uses to64() in the original code.
    
    rearranged = ""
    
    [ [0, 6, 12], [1, 7, 13], [2, 8, 14], [3, 9, 15], [4, 10, 5] ].each do |a, b, c|
      
      v = final.getbyte(a) << 16 | final.getbyte(b) << 8 | final.getbyte(c)
      
      4.times do
        rearranged += ITOA64[v & 0x3f].chr
        v >>= 6 
      end
    end
    
    v = final.getbyte(11)
    
    2.times do
      rearranged += ITOA64[v & 0x3f].chr
      v >>= 6
    end
    
    magic + salt + '$' + rearranged
  end
  
  
  # check the validity of a password against an hashed string
  
  def self.check(password, hash, options = {})
    magic, salt = hash.split('$')[1,2]
    magic = '$' + magic + '$'
    
    self.crypt(password, options.merge(:magic => magic, :salt => salt)) == hash
  end
  
  
  # generate a +size+ length random salt
  
  def self.generate_salt(size)
   (1..size).collect { ITOA64[rand(ITOA64.size)].chr }.join("")
  end
end



#  _____         _
# |_   _|__  ___| |_
#   | |/ _ \/ __| __|
#   | |  __/\__ \ |_
#   |_|\___||___/\__|
#

=begin test

  require "test/unit"

  class CryptTest < Test::Unit::TestCase

    def array_test(arr, algo)
      arr.each do |password, hash|
        assert(Crypt.check(password, hash, algo))
      end
    end

    def test_md5
      a = [ [' ', '$1$yiiZbNIH$YiCsHZjcTkYd31wkgW8JF.'],
        ['pass', '$1$YeNsbWdH$wvOF8JdqsoiLix754LTW90'],
        ['____fifteen____', '$1$s9lUWACI$Kk1jtIVVdmT01p0z3b/hw1'],
        ['____sixteen_____', '$1$dL3xbVZI$kkgqhCanLdxODGq14g/tW1'],
        ['____seventeen____', '$1$NaH5na7J$j7y8Iss0hcRbu3kzoJs5V.'],
        ['__________thirty-three___________', '$1$HO7Q6vzJ$yGwp2wbL5D7eOVzOmxpsy.'],
        ['apache', '$apr1$J.w5a/..$IW9y6DR0oO/ADuhlMF5/X1']
      ] 
      array_test(a, :md5)
    end

    def test_bad_algo
      assert_raise(ArgumentError) do 
        Crypt.crypt("qsdf", :qsdf)
      end
    end

  end

=end
