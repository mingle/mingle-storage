module Storage
  class S3Store

    HALF_AN_HOUR = 30 * 60

    def initialize(path_prefix, options)
      @path_prefix = path_prefix
      @url_expires = options[:url_expires] || HALF_AN_HOUR
      @bucket_name = options[:bucket_name]
    end

    def upload(path, local_file)
      local_file_name = File.basename(local_file)
      bucket.objects.create(
                            s3_path(path, local_file_name),
                            File.read(local_file),
                            { :content_type => derive_content_type(local_file_name) }
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

    def write_to_file(path, content)
      object(path).write(content)
    end

    def read(path)
      object(path).read
    end

    def exists?(path)
      object(path).exists?
    end

    def url_for(path)
      object(path).url_for(:read, :expires => @url_expires).to_s
    end

    #todo: this should be interface that retrive a lazy file object
    def absolute_path(*relative_paths)
      File.join("s3:#{bucket_name}://", *relative_paths)
    end

    def delete(path)
      bucket.objects.with_prefix(s3_path(path)).delete_all
    end

    def clear
      if s3_path.blank?
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
      Storage::CONTENT_TYPES[file_extension]
    end

    def s3
      AWS::S3.new
    end

    def object(path)
      bucket.objects[s3_path(path)]
    end

    def s3_path(*paths)
      File.join(*([@path_prefix, *paths].compact))
    end

    def bucket
      @bucket ||= s3.buckets[bucket_name]
    end

    def bucket_name
      @bucket_name.is_a?(String) ? @bucket_name : @bucket_name[@path_prefix]
    end
  end
end
