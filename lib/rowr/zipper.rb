require 'rowr'

module Rowr

  class Zipper

    def initialize(src_dir)
      @src = src_dir
      @filename = 'rowr_backup_files'
      @backup_dir = File.join(src, filename)
    end

    attr_accessor :src
    attr_reader   :filename
    attr_reader   :backup_dir

    def backup
      copy
      zip
      remove
    end

    def remove
      FileUtils.remove_dir(backup_dir)
    end

    def copy
      FileUtils.mkdir_p backup_dir
      files = Dir.glob(File.join(src, '*')).reject { |f| File.basename(f) == filename }
      FileUtils.cp_r files, backup_dir
    end

    def zip
      zip = File.join(src,"#{filename}.zip")
      File.delete zip if File.exist?(zip)
      zf = ZipFileGenerator.new(backup_dir, zip)
      zf.write
    end

    def restore
      delete_all_files_except_backup
      unzip
    end

    def unzip
      Zip::File.open(File.join(src, "#{filename}.zip")) do |zip_file|
        zip_file.each do |file|
          file_path = File.join(src, file.name)
          FileUtils.mkdir_p(File.dirname(file_path))
          zip_file.extract(file, file_path) unless File.exist?(file_path)
        end
      end
    end

    def backup_file_exists?
      File.exist?(File.expand_path(File.join(src, "#{filename}.zip")))
    end

    def delete_all_files_except_backup
      FileUtils.rm_rf (Dir.glob(File.join(src, '*')).reject { |f| File.basename(f) =~ /^rowr_/ })
    end

  end
end