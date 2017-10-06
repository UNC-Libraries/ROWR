require 'spec_helper'
require 'fileutils'

fake_site = File.join('spec', 'fake')
test_site = fake_site + '-test'

describe Rowr do
  it "has a version number" do
    expect(Rowr::VERSION).not_to be nil
  end

  it "has a prompter class" do
    expect(Rowr::Prompter).not_to be nil
  end

  it "has a printer class" do
    expect(Rowr::Printer).not_to be nil
  end

  it "has a state saver class" do
    expect(Rowr::StateSaver).not_to be nil
  end

  it "has a zipper class" do
    expect(Rowr::Zipper).not_to be nil
  end

  it "has a resurrector class" do
    expect(Rowr::Resurrector).not_to be nil
  end

end

describe Rowr::Prompter do

  prompter = Rowr::Prompter.new

  it 'creates an array of file extensions' do
    prompter.exts_to_use = '.xml png .jpeg'
    expect(prompter.exts_to_use).to eq(%w(htm html xml png jpeg))

    prompter.exts_to_use = nil
    expect(prompter.exts_to_use).to eq(%w(htm html))

    prompter.exts_to_use = ''
    expect(prompter.exts_to_use).to eq(%w(htm html))
  end

  it 'checks that the dir provided exists' do
    prompter.source_directory = fake_site
    expect(prompter.source_directory).to eq(File.expand_path(fake_site))
  end

  it 'cleans the old domain' do
    prompter.old_host = 'https://www.google.com'
    expect(prompter.old_host).to eq('www.google.com')

    prompter.old_host = 'http://www.google.com'
    expect(prompter.old_host).to eq('www.google.com')

    prompter.old_host = 'www.google.com'
    expect(prompter.old_host).to eq('www.google.com')

    prompter.old_host = ''
    expect(prompter.old_host).to be false

  end


  it 'cleans the new base url' do
    prompter.new_base_path = 'www.google.com'
    expect(prompter.new_base_path).to eq('/')

    prompter.new_base_path = 'https://www.google.com/'
    expect(prompter.new_base_path).to eq('/')

    prompter.new_base_path = 'https://www.google.com/base'
    expect(prompter.new_base_path).to eq('/base/')

    prompter.new_base_path = 'base'
    expect(prompter.new_base_path).to eq('/base/')

    prompter.new_base_path = '/base'
    expect(prompter.new_base_path).to eq('/base/')

    prompter.new_base_path = '/base/'
    expect(prompter.new_base_path).to eq('/base/')

    prompter.new_base_path = '/'
    expect(prompter.new_base_path).to eq('/')

    prompter.new_base_path = '/base/path'
    expect(prompter.new_base_path).to eq('/base/path/')

    prompter.new_base_path = nil
    expect(prompter.new_base_path).to eq('/')

    prompter.new_base_path = 'https://www.google.com/base/to/somewhere'
    expect(prompter.new_base_path).to eq('/base/to/somewhere/')

    prompter.new_base_path = 'www.google.com/base/to/somewhere'
    expect(prompter.new_base_path).to eq('/base/to/somewhere/')

    prompter.new_base_path = 'base/to/somewhere'
    expect(prompter.new_base_path).to eq('/base/to/somewhere/')

  end

end

describe Rowr::Zipper do

  zipper = Rowr::Zipper.new test_site
  filename = 'rowr_backup_files'
  backup_dir = File.join(test_site, filename)

  before(:all) do
    FileUtils.copy_entry(fake_site, test_site)
  end

  it 'is sets the filename name' do
    expect(zipper.backup_dir).to eq(backup_dir)
  end

  it 'makes a copy of the contents of the site directory' do
    zipper.copy

    top_test = File.join(backup_dir, 'file.htm')
    expect(File.exist?(top_test)).to be true
    sub_test = File.join(backup_dir, 'subdir', 'file.htm')
    expect(File.exist?(sub_test)).to be true
  end

  it 'zips the backup' do
    zipper.zip

    zip_test = File.join(test_site, "#{filename}.zip")
    expect(File.exist?(zip_test)).to be true
  end

  it 'removes the backup dir' do
    zipper.remove

    remove_test = File.join(test_site, 'backup')
    expect(Dir.exist?(remove_test)).to be false
  end

  it 'removes all files except the backup dir' do
    zipper.delete_all_files_except_backup

    dir_test = File.join(test_site, 'subdir')
    expect(Dir.exist?(dir_test)).to be false

    file_test = File.join(test_site, 'image.png')
    expect(File.exist?(file_test)).to be false

    zip_test = File.join(test_site, 'rowr_backup_files.zip')
    expect(File.exist?(zip_test)).to be true
  end

  it 'unzips the backup' do
    zipper.unzip

    dir_test = File.join(test_site, 'subdir')
    expect(Dir.exist?(dir_test)).to be true

    subdir_file_test = File.join(test_site, 'subdir', 'file.htm')
    expect(File.exist?(subdir_file_test)).to be true

    file_test = File.join(test_site, 'image.png')
    expect(File.exist?(file_test)).to be true

    zip_test = File.join(test_site, 'rowr_backup_files.zip')
    expect(File.exist?(zip_test)).to be true
  end

  after(:all) do
    FileUtils.remove_dir test_site
  end
end

describe Rowr::LinkProcessor do


  before(:all) do
    FileUtils.copy_entry(fake_site, test_site)
    @processor = Rowr::LinkProcessor.new(
      File.expand_path(test_site),
      'www.google.com',
      '/base/',
      true
    )
  end

  it 'processes an existing file targeted by an absolute link' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'file.htm'))
    @processor.link_to_check = '/subdir/file.htm'
    expect(@processor.process_link).to eq('/base/subdir/file.htm')
  end

  it 'processes an existing directory targeted by an absolute link' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'file.htm'))
    @processor.link_to_check = '/subdir'
    expect(@processor.process_link).to eq('/base/subdir')
    @processor.link_to_check = '/subdir/'
    expect(@processor.process_link).to eq('/base/subdir/')
  end

  it 'processes an existing file targeted by a relative link' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'file.htm'))
    @processor.link_to_check = 'subdir/file.htm'
    expect(@processor.process_link).to eq('/base/subdir/file.htm')
  end

  it 'processes an existing directory targeted by an relative link' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'file.htm'))
    @processor.link_to_check = 'subdir'
    expect(@processor.process_link).to eq('/base/subdir')
    @processor.link_to_check = 'subdir/'
    expect(@processor.process_link).to eq('/base/subdir/')
  end

  it 'processes an existing file targeted by a nested relative link' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'subdir/file.htm'))
    @processor.link_to_check = 'style.css'
    expect(@processor.process_link).to eq('/base/subdir/style.css')
  end

  it 'processes an existing directory targeted by a nested relative link' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'subdir/file.htm'))
    @processor.link_to_check = 'subdir2'
    expect(@processor.process_link).to eq('/base/subdir/subdir2')
    @processor.link_to_check = 'subdir2/'
    expect(@processor.process_link).to eq('/base/subdir/subdir2/')
  end

  it 'processes an existing file targeted by a uri' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'subdir/file.htm'))
    @processor.link_to_check = 'https://www.google.com/subdir/style.css'
    expect(@processor.process_link).to eq('/base/subdir/style.css')
  end

  it 'processes an existing directory targeted by a uri' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'file.htm'))
    @processor.link_to_check = 'https://www.google.com/subdir'
    expect(@processor.process_link).to eq('/base/subdir')
    @processor.link_to_check = 'https://www.google.com/subdir/'
    expect(@processor.process_link).to eq('/base/subdir/')
  end

  it 'returns nil if the file does not exist' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'file.htm'))
    @processor.link_to_check = 'image2.png'
    expect(@processor.process_link).to eq(nil)
  end

  it 'returns nil if the directory does not exist' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'file.htm'))
    @processor.link_to_check = 'badsubdir'
    expect(@processor.process_link).to eq(nil)
    @processor.link_to_check = 'badsubdir/'
    expect(@processor.process_link).to eq(nil)
  end

  it 'adds a link to the cache' do
    @processor.containing_file = File.expand_path(File.join(test_site, 'file.htm'))
    @processor.link_to_check = 'https://www.google.com/subdir/file.htm'
    @processor.add_to_cache('/subdir/file.htm')
    test_key = 'subdir/file.htm'.to_sym
    test_cache = {
        test_key => '/subdir/file.htm'
    }
    expect(@processor.cached).to eq(test_cache)
  end

  it 'checks the cache for an existing key' do
    @processor.link_to_check = '/subdir/file.htm'
    expect(@processor.in_cache?).to be true
  end

  it 'recommends match files' do
    @processor.link_to_check = 'image.png'
    files = %w(/image.png /subdir/image.png)
    expect(@processor.recommend_files).to eq(files)
  end

  it 'knows the difference between external sites and uri\'s within scope' do
    expect(@processor.external?('https://www.google.com/subdir/file.htm')).to be false
    expect(@processor.external?('image.jpeg')).to be false
    expect(@processor.external?('https://www.facebook.com/other/dir/index.php')).to be true
  end

  it 'checks the http response code of an external site' do

    @processor.link_to_check = 'https://www.playmakers.org'
    expect(@processor.broken_external_link?).to be true

    @processor.link_to_check = 'https://www.facebook.com'
    expect(@processor.broken_external_link?).to be false

    @processor.link_to_check = 'https://www.facebook.com'
    expect(@processor.broken_external_link?).to be false

    @processor.link_to_check = 'https://www.facebook.com/other/dir/index.php'
    expect(@processor.broken_external_link?).to be true
  end

  it 'prepends the base path' do
    @processor.new_base_path = '/base/'
    expect(@processor.prepend_new_base_path('base')).to eq('/base/')
    expect(@processor.prepend_new_base_path('/')).to eq('/base/')
    expect(@processor.prepend_new_base_path('/base/path/file.htm')).to eq('/base/path/file.htm')
    expect(@processor.prepend_new_base_path('base/path/file.htm')).to eq('/base/path/file.htm')

    @processor.new_base_path = '/'
    expect(@processor.prepend_new_base_path('base')).to eq('/base')
    expect(@processor.prepend_new_base_path('/')).to eq('/')
    expect(@processor.prepend_new_base_path('/path/file.htm')).to eq('/path/file.htm')
    expect(@processor.prepend_new_base_path('path/file.htm')).to eq('/path/file.htm')
  end


  after(:all) do
    FileUtils.remove_dir test_site
  end

end

describe Rowr::StateSaver do

  before(:all) do
    FileUtils.copy_entry(fake_site, test_site)
    @saver = Rowr::StateSaver.new test_site, 'rowr_config.json'
    @file = File.expand_path(File.join(test_site, 'rowr_config.json'));
  end

  it 'saves a state file' do
    @saver.save_state
    expect(File.exist?(@file)).to be true
  end

  it 'saves a config setting' do
    config = { who: 'first', what: 'second'}
    @saver.save_config config
    saved_config = JSON.parse(File.open(@file).read, symbolize_names: true)
    expect(saved_config[:config]).to eq(config)
  end

  it 'loads a state' do
    state = { config: {who: 'first', what: 'second'}, cached: { :'/path/one' => '/replace/path' }, scanned_files: ['/file/one.html']}
    File.open(@file, 'wb') { |f| f.write JSON.pretty_generate(state) }
    @saver.load_state

    expect(@saver.config).to eq(state[:config])
    expect(@saver.cached).to eq(state[:cached])
    expect(@saver.scanned_files).to eq(state[:scanned_files])
  end

  after(:all) do
    FileUtils.remove_dir test_site
  end


end
