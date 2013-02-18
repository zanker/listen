def mac?
  RbConfig::CONFIG['target_os'] =~ /darwin/i
end

def linux?
  RbConfig::CONFIG['target_os'] =~ /linux/i
end

def bsd?
  RbConfig::CONFIG['target_os'] =~ /freebsd/i
end

def windows?
  RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
end

def jruby_with_java51?
  RUBY_ENGINE == "jruby" and java.lang.System.getProperties["java.class.version"].to_f >= 51
end