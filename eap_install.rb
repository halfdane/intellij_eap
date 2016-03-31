#!/usr/bin/ruby
require 'net/http'
require 'uri'
require 'fileutils'
require File.expand_path(File.dirname(__FILE__) + '/config')


def log message
    `logger -t "Intellij installer" -s "#{message}"`
end

def last_build_download_urls
    log "checking latest EAP build"
    url = URI.parse("http://confluence.jetbrains.com" + EAP_URL)
    eap_page = Net::HTTP.start(url.host, url.port) do |http|
        http.get(EAP_URL)
    end

    download_pattern = /.*(https\:\/\/download\.jetbrains\.com\/idea\/ideaIU[^"]+\.tar\.gz)".*/m
    
    download_url = download_pattern.match(eap_page.body)[1]
    log "   found #{download_url}"

    return download_url
end

def download force = false
    download_path = File.expand_path(DOWNLOAD_PATH)
    FileUtils.mkdir_p download_path unless File.exists?(download_path)
    
    url = last_build_download_urls
    
    filename = download_path + "/" + url.gsub(/.+\//, '')
    if File.exists? filename then
        log "#{url} is already downloaded: #{filename}"
        return false unless force
        log "download is forced"
        `rm #{filename}`
    end

    log "downloading #{url}..."
    Dir.chdir(download_path){ `wget #{url}` }
    return true
end


def install_idea filepath, force = false
    filepath = find_latest_distr
    filename = File.basename(filepath)
    installation_path = File.expand_path(INSTALLATION_PATH)
            
    dest_dir = installation_path + "/" + `ls -t #{installation_path} | head -n 1`.strip
    log "dest_dir: #{dest_dir}"

    begin
        FileUtils.mkdir_p installation_path unless File.exists?(installation_path)
        
        Dir.chdir(installation_path) do
            log "untarring '#{filename}'"
            `tar xzf #{filepath}`
        end
    end

    if defined?(LINK_TO)
        link_to = File.expand_path(LINK_TO)
        log "linking #{dest_dir} to #{link_to}"
        `rm -f #{link_to} && ln -sf #{dest_dir} #{LINK_TO}`
    end

    log "installation finished"
end

def find_latest_distr
    download_path = File.expand_path(DOWNLOAD_PATH)
    Dir.glob("#{download_path}/idea*.tar.gz").sort_by { |f| File.new(f).mtime }.last
end



argv = ARGV.join("")
force = argv.include?("f")

log "Checking for new versions"
download(force)
install_idea(force)



