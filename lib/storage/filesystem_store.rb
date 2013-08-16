module Storage
  class FilesystemStore
    def initialize(path_prefix, options={})
      @dir = options[:root_path] || raise('Must define root path for file system store')
      @path_prefix = path_prefix
      FileUtils.mkdir_p File.join(@dir, @path_prefix)
    end

    def copy(path, to_local_path)
      raise "File(#{path}) does not exist" unless File.exists?(absolute_path(path))
      FileUtils.cp(absolute_path(path), to_local_path)
    end

    def read(path)
      File.read(absolute_path(path))
    end

    def upload(path, local_file)
      FileUtils.mkdir_p(absolute_path(path))
      FileUtils.mv(local_file, absolute_path(path))
    end

    def upload_dir(path, local_dir)
      FileUtils.rm_rf(absolute_path(path))
      Dir[File.join(local_dir, "*")].each do |f|
        upload(path, f)
      end
    end

    #todo: this should be interface that retrive a lazy file object
    def absolute_path(*relative_paths)
      File.join(@dir, @path_prefix, *relative_paths)
    end

    def exists?(path)
      File.exists?(absolute_path(path))
    end

    def delete(path)
      FileUtils.rm_rf(absolute_path(path))
    end

    def clear
      FileUtils.rm_rf File.join(@dir, @path_prefix)
    end
  end
end
