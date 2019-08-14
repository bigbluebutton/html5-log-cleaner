#!/usr/bin/ruby

# Cleans the html5 client logs due to nginx encoding.

require 'json'
require 'date'
require 'time'
require 'logger'

class NginxLogUnescaper
  NGINX_UNESCAPE_MAP = {}

    256.times do |i|
        h, l = i>>4, i&15
        c = i.chr.freeze
        k = sprintf('\\x%X%X', h, l).freeze
        NGINX_UNESCAPE_MAP[k] = c
    end
    NGINX_UNESCAPE_MAP.freeze

    def self.unescape(str)
        str.b.gsub(/\\x[0-9A-F][0-9A-F]/, NGINX_UNESCAPE_MAP).force_encoding(Encoding::UTF_8)
    end
end

def valid_json?(json)
  begin
    JSON.parse(json)
    return true
  rescue Exception => e
    return false
  end
end

def scrub_line_to_remove_illegal_chars(line)
    # https://stackoverflow.com/questions/24036821/ruby-2-0-0-stringmatch-argumenterror-invalid-byte-sequence-in-utf-8
    line.scrub
end

if ENV['LOG_PATH'].nil?
  logger = Logger.new(STDOUT)
else
  log_path = ENV['LOG_PATH']
  logger = Logger.new("#{log_path}", 'daily', 14)
end

logger.level = Logger::INFO
logger.formatter = proc do |severity, datetime, progname, msg|
  JSON.dump(msg) + "\n"
end

LINE_RE = /([^ ]*) \[([^\]]*)\] (.*)/
COMPONENT = "html5-client"

ARGF.each do |log_line|
  line = NginxLogUnescaper.unescape(log_line)
  scrubbed = scrub_line_to_remove_illegal_chars(line)

  if result = LINE_RE.match(scrubbed)
    log_ip = result[1]
    log_server_date = result[2]
    payload = result[3]

    server_date_iso8601 = DateTime.parse(log_server_date).iso8601(3)

    if valid_json?(payload)
      begin
        data = JSON.parse(payload)
        data.each do |log|
          raw_log = {
            timestamp: server_date_iso8601,
            ip: log_ip,
            payload: log
          }
          logger.info raw_log
        end
      rescue StandardError => msg
        #puts msg
      end
    else
     #puts "Unable to parse #{scrubbed}"
    end
  end
end
