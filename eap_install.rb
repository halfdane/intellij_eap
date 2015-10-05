#!/usr/bin/ruby
require 'fileutils'
require File.expand_path(File.dirname(__FILE__) + '/config')

class Downloader
    def download_idea force = false
        download(last_build_download_urls, force)
    end

    private

    def download url, force = false
        download_path = File.expand_path(DOWNLOAD_PATH)
        
        filename = download_path + "/" + url.gsub(/.+\//, '')
        if File.exists? filename then
            puts "#{url} is already downloaded: #{filename}"
            return unless force
            puts "download is forced"
            `rm #{filename}`
        end

        puts "downloading #{url}..."
        Dir.chdir(download_path){ `wget #{url}` }
    end

    def last_build_download_urls
        return @urls unless @urls.nil?

        require 'net/http'
        require 'uri'

        download_url = nil
        eap_page = nil

        puts "checking latest EAP build"
        url = URI.parse("http://confluence.jetbrains.com" + EAP_URL)
        eap_page = Net::HTTP.start(url.host, url.port) do |http|
            http.get(EAP_URL)
        end

        download_pattern = /.*(https\:\/\/download\.jetbrains\.com\/idea\/ideaIU[^"]+\.tar\.gz)".*/m
        download_url = download_pattern.match(eap_page.body)[1]
        puts "   found #{download_url}"

        return (@urls = download_url)
    end
end

class Installer
    def install_latest_idea force
        install_idea(find_latest_distr, force)
    end

    private

    def install_idea filepath, force = false
        filename = File.basename(filepath)
        installation_path = File.expand_path(INSTALLATION_PATH)
        
        Dir.chdir(installation_path) do
            puts "untarring '#{filename}'"
            `tar zxfv #{filepath}`
        
        end
        
        dest_dir = installation_path + "/" + `ls -t #{installation_path} | head -n 1`.strip
        puts "dest_dir: #{dest_dir}"

<<<<<<< HEAD
        begin
            FileUtils.mkdir_p installation_path unless File.exists?(installation_path)
            
            Dir.chdir(installation_path) do
                puts "untarring '#{filename}'"
                `tar zxfv #{filepath}`
            end
            if defined?(IDEA_CONFIG)
                puts "copying config"
                `cp -r #{IDEA_CONFIG}/* #{dest_dir}/bin`
            end
=======
        if defined?(IDEA_CONFIG)
            puts "copying config"
            `cp -r #{IDEA_CONFIG}/* #{dest_dir}/bin`
>>>>>>> Simplify installation process
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

end


argv = ARGV.join("")
force = argv.include?("f")

d = Downloader.new
d.download_idea(force)

i = Installer.new
i.install_latest_idea(force)


