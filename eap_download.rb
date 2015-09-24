#!/usr/bin/ruby
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


force = ARGV.include?("f")

d = Downloader.new
d.download_idea(force)
