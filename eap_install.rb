#!/usr/bin/ruby
require File.expand_path(File.dirname(__FILE__) + '/config')

class Installer
    def install_latest_idea force
        install_idea(find_latest_distr, force)
    end

    private

    def install_idea filepath, force = false
        filename = File.basename(filepath)
        installation_path = File.expand_path(INSTALLATION_PATH)
        dest_dir = installation_path + "/" + distr_to_dir_name(filename)
        if File.exists? dest_dir then
            puts "the latest downloaded version (#{filename}) seems to be already installed: #{dest_dir}"
            return unless force
            puts "install is forced"
            `rm -rf #{dest_dir}`
        end

        begin
            Dir.chdir(installation_path) do
                puts "untarring '#{filename}'"
                `tar zxfv #{filepath}`
            end
            if defined?(IDEA_CONFIG)
                puts "copying config"
                `cp -r #{IDEA_CONFIG}/* #{dest_dir}/bin`
            end
        end

        if defined?(LINK_TO)
            link_to = File.expand_path(LINK_TO)
            puts "linking #{dest_dir} to #{link_to}"
            `rm -f #{link_to} && ln -sf #{dest_dir} #{LINK_TO}`
        end

        puts "installation finished"
    end

    def find_latest_distr
        download_path = File.expand_path(DOWNLOAD_PATH)
        Dir.glob("#{download_path}/idea*.tar.gz").sort_by { |f| File.new(f).mtime }.last
    end

    def distr_to_dir_name filename
        "#{filename[0..3]}-#{filename[4..-8]}"
    end

end


argv = ARGV.join("")
force = argv.include?("f")

i = Installer.new
i.install_latest_idea(force)
