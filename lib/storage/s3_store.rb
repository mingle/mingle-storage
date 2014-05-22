module Storage
  class S3Store

    HALF_AN_HOUR = 30 * 60

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
      "avi" => "video/x-msvideo",
      "docx" => "application/x-word",
      "xlsx" => "application/x-excel",
      "pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "eml" => "text/plain",
      "msg" => "text/plain"
    }


    def initialize(path_prefix, options)
      @path_prefix = path_prefix
      @url_expires = options[:url_expires] || HALF_AN_HOUR
      @bucket_name = options[:bucket_name]
      @namespace = options[:namespace]
    end

    def upload(path, local_file, options={})
      local_file_name = File.basename(local_file)
      bucket.objects.create(
                            s3_path(path, local_file_name),
                            Pathname.new(local_file),
                            { :content_type => derive_content_type(local_file_name) }.merge(options)
                            )
    end

    def upload_dir(path, local_dir)
      bucket.objects.with_prefix(s3_path(path)).delete_all
      Dir[File.join(local_dir, "*")].each do |f|
        upload(path, f)
      end
    end

    def content_type(path)
      object(path).content_type
    end

    def copy(path, to_local_path)
      obj = object(path)
      raise "File(#{path}) does not exist in the bucket #{bucket.name}" unless obj.exists?
      File.open(to_local_path, 'w') do |f|
        obj.read do |c|
          f.write(c)
        end
      end
    end

    def write_to_file(path, content, options={})
      object(path).write(content, options)
    end

    def read(path)
      object(path).read
    end

    def exists?(path)
      object(path).exists?
    end

    def url_for(path, opts={})
      object(path).url_for(:read,
                           :expires => opts[:expires_in] || @url_expires,
                           :response_content_type => derive_content_type(path)).to_s
    end

    def public_url(path, opts={})
      object(path).public_url(opts)
    end

    #todo: this should be interface that retrive a lazy file object
    def absolute_path(*relative_paths)
      File.join("s3:#{bucket_name}://", *relative_paths)
    end

    def delete(path)
      bucket.objects.with_prefix(s3_path(path)).delete_all
    end

    def clear
      if s3_path.nil? || s3_path.empty?
        bucket.clear
      else
        bucket.objects.with_prefix(s3_path).delete_all
      end
    end

    def objects(path)
      bucket.objects.with_prefix(s3_path(path))
    end

    private
    def derive_content_type(file_name)
      file_extension = file_name.split(".").last
      CONTENT_TYPES[file_extension]
    end

    def s3
      AWS::S3.new
    end

    def object(path)
      bucket.objects[s3_path(path)]
    end

    def namespace
      Proc === @namespace ? @namespace.call : @namespace
    end

    def s3_path(*paths)
      File.join(*([namespace, @path_prefix, *paths].compact))
    end

    def bucket
      @bucket ||= s3.buckets[bucket_name]
    end

    def bucket_name
      @bucket_name.is_a?(String) ? @bucket_name : @bucket_name[@path_prefix]
    end
  end
end
