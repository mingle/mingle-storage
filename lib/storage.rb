require 'rubygems'
require 'aws-sdk'
require 'storage/filesystem_store.rb'
require 'storage/s3_store.rb'

module Storage

  CONTENT_TYPES = {
    "html" => "text/html",
    "htm" => "text/html",
    "shtml" => "text/html",
    "css" => "text/css",
    "xml" => "text/xml",
    "gif" => "image/gif",
    "jpeg" => "image/jpeg",
    "jpg" => "image/jpeg",
    "js" => "application/x-javascript",
    "atom" => "application/atom+xml",
    "rss" => "application/rss+xml",
    "json" => "application/json",
    "mml" => "text/mathml",
    "txt" => "text/plain",
    "jad" => "text/vnd.sun.j2me.app-descriptor",
    "wml" => "text/vnd.wap.wml",
    "htc" => "text/x-component",
    "png" => "image/png",
    "tif" => "image/tiff",
    "tiff" => "image/tiff",
    "wbmp" => "image/vnd.wap.wbmp",
    "ico" => "image/x-icon",
    "jng" => "image/x-jng",
    "bmp" => "image/x-ms-bmp",
    "svg" => "image/svg+xml",
    "jar" => "application/java-archive",
    "war" => "application/java-archive",
    "ear" => "application/java-archive",
    "hqx" => "application/mac-binhex40",
    "doc" => "application/msword",
    "pdf" => "application/pdf",
    "ps" => "application/postscript",
    "eps" => "application/postscript",
    "ai" => "application/postscript",
    "rtf" => "application/rtf",
    "xls" => "application/vnd.ms-excel",
    "ppt" => "application/vnd.ms-powerpoint",
    "wmlc" => "application/vnd.wap.wmlc",
    "xhtml" => "application/vnd.wap.xhtml+xml",
    "kml" => "application/vnd.google-earth.kml+xml",
    "kmz" => "application/vnd.google-earth.kmz",
    "7z" => "application/x-7z-compressed",
    "cco" => "application/x-cocoa",
    "jardiff" => "application/x-java-archive-diff",
    "jnlp" => "application/x-java-jnlp-file",
    "run" => "application/x-makeself",
    "pl" => "application/x-perl",
    "pm" => "application/x-perl",
    "prc" => "application/x-pilot",
    "pdb" => "application/x-pilot",
    "rar" => "application/x-rar-compressed",
    "rpm" => "application/x-redhat-package-manager",
    "sea" => "application/x-sea",
    "swf" => "application/x-shockwave-flash",
    "sit" => "application/x-stuffit",
    "tcl" => "application/x-tcl",
    "tk" => "application/x-tcl",
    "der" => "application/x-x509-ca-cert",
    "pem" => "application/x-x509-ca-cert",
    "crt" => "application/x-x509-ca-cert",
    "xpi" => "application/x-xpinstall",
    "zip" => "application/zip",
    "bin" => "application/octet-stream",
    "exe" => "application/octet-stream",
    "dll" => "application/octet-stream",
    "deb" => "application/octet-stream",
    "dmg" => "application/octet-stream",
    "eot" => "application/octet-stream",
    "iso" => "application/octet-stream",
    "img" => "application/octet-stream",
    "msi" => "application/octet-stream",
    "msp" => "application/octet-stream",
    "msm" => "application/octet-stream",
    "mid" => "audio/midi",
    "midi" => "audio/midi",
    "kar" => "audio/midi",
    "mp3" => "audio/mpeg",
    "ra" => "audio/x-realaudio",
    "3gpp" => "video/3gpp",
    "3gp" => "video/3gpp",
    "mpeg" => "video/mpeg",
    "mpg" => "video/mpeg",
    "mov" => "video/quicktime",
    "flv" => "video/x-flv",
    "mng" => "video/x-mng",
    "asx" => "video/x-ms-asf",
    "asf" => "video/x-ms-asf",
    "wmv" => "video/x-ms-wmv",
    "avi" => "video/x-msvideo"
  }

  class Builder
    def initialize(type)
      @type = type
    end

    def build(path_prefix, options={})
      store_class.new(path_prefix, options)
    end

    private

    def store_class
      {
        :filesystem => Storage::FilesystemStore,
        :s3 => Storage::S3Store
      }[@type.to_sym]
    end
  end

  def self.store(type, path_prefix, options={})
    builder = Builder.new(type)
    builder.build(path_prefix, options)
  end

end
