require 'test/unit'
require 'storage'
require 'fileutils'
require 'tmpdir'
require 'rubygems'
require 'active_support'

class StorageTest < Test::Unit::TestCase
  extend Test::Unit::Assertions

  ROOT_DIR = File.dirname(__FILE__)+"/public/entry"
  S3_CONFIG = {:bucket_name => ENV["S3_BUCKET_NAME"]}
  STORE_BUILD_OPTS = [
                      [:filesystem, {:root_path => ROOT_DIR }],
                      [:s3, S3_CONFIG]
                     ]

  def teardown
    FileUtils.rm_rf("#{tmp_dir}/file_column_test")
  end

  def self.storage_configured?(store_type)
    return !ENV["AWS_ACCESS_KEY_ID"].nil? && !ENV["AWS_ACCESS_KEY_ID"].empty? if store_type == :s3
    true
  end

  def self.store_test(test_name, store_type, build_opts, &block)
    define_method(test_name + "_for_#{store_type}_store") do
      if !self.class.storage_configured?(store_type)
        puts "Warning #{store_type} storage is not configured, test will be ignored"
        return
      end
      store = Storage.store(store_type, "foo", build_opts)
      begin
        yield(store)
      ensure
        store.clear
      end
    end
  end

  def self.tmp_dir
    defined?(RAILS_TMP_DIR) ? RAILS_TMP_DIR : Dir.tmpdir
  end

  def tmp_dir
    self.class.tmp_dir
  end

  def self.create_local_file(path, content="abc")
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, "w+") { |f| f << content }
    path
  end


  STORE_BUILD_OPTS.each do |store_type, build_opts|
    store_test "test_build_right_store", store_type, build_opts do |store|
      assert store.class.name.include?(ActiveSupport::Inflector.camelize(store_type))
    end

    store_test "test_upload_local_file", store_type, build_opts do |store|
      store.upload("x/y/z", create_local_file("#{tmp_dir}/file_column_test/abc", "123"))
      assert !store.exists?("x/abc")
      assert store.exists?("x/y/z/abc")
      assert_equal "123", store.read("x/y/z/abc")
    end

    store_test "test_clear_store", store_type, build_opts do |store|
      store_a = Storage.store(store_type, "foo", build_opts)
      store_b = Storage.store(store_type, "bar", build_opts)
      store_a.upload("x/y/z", create_local_file("#{tmp_dir}/file_column_test/abc"))
      store_b.upload("x/y/z", create_local_file("#{tmp_dir}/file_column_test/abc"))

      assert store_a.exists?("x/y/z/abc")
      assert store_b.exists?("x/y/z/abc")

      store_a.clear

      assert !store_a.exists?("x/y/z/abc")
      assert store_b.exists?("x/y/z/abc")

      store_b.clear

      assert !store_a.exists?("x/y/z/abc")
      assert !store_b.exists?("x/y/z/abc")
    end

    store_test "test_delete_files_under_a_path", store_type, build_opts do |store|
      store.upload("x/y/z", create_local_file("#{tmp_dir}/file_column_test/a"))
      store.upload("x/y/z/k", create_local_file("#{tmp_dir}/file_column_test/b"))
      store.upload("x/y/s", create_local_file("#{tmp_dir}/file_column_test/c"))


      store.delete("x/y/z")
      assert !store.exists?("x/y/z/a")
      assert !store.exists?("x/y/z/k/b")
      assert store.exists?("x/y/s/c")
    end

    store_test "test_upload_with_same_name_replace_file", store_type, build_opts do |store|
      store.upload("x/y/z", create_local_file("#{tmp_dir}/file_column_test/abc", "123"))
      assert_equal "123", store.read("x/y/z/abc")

      store.upload("x/y/z", create_local_file("#{tmp_dir}/file_column_test/abc", "456"))
      assert_equal "456", store.read("x/y/z/abc")
    end

    store_test "test_upload_local_dir", store_type, build_opts do |store|
      create_local_file("#{tmp_dir}/file_column_test/a")
      create_local_file("#{tmp_dir}/file_column_test/b")
      store.upload_dir("x/y/z", "#{tmp_dir}/file_column_test")

      assert store.exists?("x/y/z/a")
      assert store.exists?("x/y/z/b")
    end

    store_test "test_upload_local_dir_with_replace_files", store_type, build_opts do |store|

      create_local_file("#{tmp_dir}/file_column_test/old/a")
      store.upload_dir("x/y/z", "#{tmp_dir}/file_column_test/old")

      create_local_file("#{tmp_dir}/file_column_test/new/b")
      store.upload_dir("x/y/z", "#{tmp_dir}/file_column_test/new")

      assert store.exists?("x/y/z/b")
      assert !store.exists?("x/y/z/a")
    end

    store_test 'test_copy_file_to_local_path', store_type, build_opts do |store|
      create_local_file("#{tmp_dir}/file_column_test/old/a")
      store.upload_dir("x/y/z", "#{tmp_dir}/file_column_test/old")
      FileUtils.mkdir_p("#{tmp_dir}/file_column_test/new")
      store.copy('x/y/z/a', "#{tmp_dir}/file_column_test/new/a")
      assert_equal 'abc', File.read("#{tmp_dir}/file_column_test/new/a")
    end

    store_test 'test_should_not_create_local_file_if_the_file_does_not_exist_on_s3', store_type, build_opts do |store|
      FileUtils.mkdir_p("#{tmp_dir}/file_column_test")
      assert_raise RuntimeError do
        store.copy('xx', "#{tmp_dir}/file_column_test/xx")
      end
      assert !File.exists?("#{tmp_dir}/file_column_test/xx")
    end
  end

  if storage_configured?(:s3)
    def store
      @store ||= Storage.store(:s3, "foo", S3_CONFIG)
    end

    def test_generate_signed_url_for_s3_store
      self.class.create_local_file("#{tmp_dir}/file_column_test/a.jpg")

      store.upload_dir("x/y/z", "tmp/file_column_test")
      url = URI.parse(store.url_for("x/y/z/a.jpg"))
      assert url.path.include?("/foo/x/y/z/a.jpg")
      assert url.query.include?("Signature")
      assert url.query.include?("Expires")
    end

    def test_sets_content_type_on_uploaded_files
      local_file = self.class.create_local_file("#{tmp_dir}/file_column_test/a.jpg")

      store.upload("x/y/z", local_file)
      assert_equal "image/jpeg", store.content_type("x/y/z/a.jpg")
    end

    def test_ignores_content_type_if_none_found
      local_file = self.class.create_local_file("#{tmp_dir}/file_column_test/a")

      store.upload("x/y/z", local_file)
      assert_equal "", store.content_type("x/y/z/a")
    end

    def test_should_write_content_to_file
      file_name = "test.txt"
      assert !store.exists?(file_name)
      store.write_to_file(file_name, "raw content")
      assert store.exists?(file_name)
      assert_equal "raw content", store.read(file_name)
    end

    def test_should_give_objects_with_prefix
      path = "project1/card1"
      file1 = "#{path}/test1"
      file2 = "#{path}/test2"
      store.write_to_file(file1, "raw content")
      store.write_to_file(file2, "raw content")

      objects_in_path = store.objects(path)
      assert_equal 2, objects_in_path.count
      keys = objects_in_path.map(&:key)

      assert_equal "foo/#{file1}", keys.first
      assert_equal "foo/#{file2}", keys.last
    end
  end
end
