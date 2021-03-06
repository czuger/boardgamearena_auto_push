require 'pathname'
require 'yaml'

class Watcher

  def initialize

    cnf = YAML::load_file('config.yml')

    @path_to_monitor = cnf[:path_to_monitor]
    @exclusion_list = cnf[:exclusion_list]

    @sftp_site = cnf[:sftp_site]
    @sftp_path = cnf[:sftp_path]

    @last_modification_time = {}
  end

  def do
    loop do
      sleep 1
      Dir.glob("#{@path_to_monitor}/**/*").each do |f|
        process_file f
      end
    end
  end

  private

  def sftp_file(path)
    absolute_path = Pathname.new(path)
    relative_root = Pathname.new(@path_to_monitor)

    relative_path = absolute_path.relative_path_from(relative_root)

    # p relative_path.dirname.to_s

    sftp_command = "sftp #{@sftp_site}:#{@sftp_path}/#{relative_path.dirname.to_s} <<< $'put #{path}'"
    p sftp_command
    system( sftp_command )
  end

  def process_file(path)
    @exclusion_list.each do |el_elem|
      return if path =~ /.*#{el_elem}.*/
    end

    if @last_modification_time[path]
      if File.mtime(path) != @last_modification_time[path]
        p "#{path} modified at #{File.mtime(path)}"

        sftp_file path
        @last_modification_time[path] = File.mtime(path)
      end
    else
      @last_modification_time[path] = File.mtime(path)
    end
  end

end

Watcher.new.do