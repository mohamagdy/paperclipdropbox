module Paperclipdropbox
  require 'paperclipdropbox/railtie' if defined?(Rails)
end

module Paperclip
	module Storage
		module Dropboxstorage
    extend self
    
			def self.extended(base)
				require "dropbox_sdk"
				base.instance_eval do
					
					@dropbox_key = @options[:dropbox_key] || '8ti7qntpcysl91j'
					@dropbox_secret = @options[:dropbox_secret] || 'i0tshr4cpd1pa4e'

					@dropbox_public_url = "http://dl.dropbox.com/u/"
					@options[:url] ="#{@dropbox_public_url}#{user_id}#{@options[:path]}"
					@url = @options[:url]
					@path = @options[:path]
					log("Starting up DropBox Storage")
				end
			end

			def exists?(style = default_style)
				log("exists?  #{style}") if respond_to?(:log)
				begin
					dropbox_client.metadata("/Public#{File.dirname(path(style))}")
					log("true") if respond_to?(:log)
					true
				rescue
					log("false") if respond_to?(:log)
					false
				end
			end

			def to_file(style=default_style)
				log("to_file  #{style}") if respond_to?(:log)
				return @queued_for_write[style] || "#{@dropbox_public_url}#{user_id}/#{path(style)}"
			end

			def flush_writes #:nodoc:
				log("[paperclip] Writing files #{@queued_for_write.count}")
				@queued_for_write.each do |style, file|
					log("[paperclip] Writing files for ") if respond_to?(:log)
					dropbox_client.put_file("/Public#{File.dirname(path(style))}/#{File.basename(path(style))}", File.open(file.path))
				end
				@queued_for_write = {}
			end

			def flush_deletes #:nodoc:
				@queued_for_delete.each do |path|
					log("[paperclip] Deleting files for #{path}") if respond_to?(:log)
					begin
						dropbox_client.rm("/Public/#{path}")
					rescue
					end
				end
				@queued_for_delete = []
			end

			def user_id
				unless Rails.cache.exist?('DropboxSession:uid')
					log("get Dropbox Session User_id")
					Rails.cache.write('DropboxSession:uid', dropbox_client.account_info['uid'])
					dropbox_client.account_info['uid']
				else
					log("read Dropbox User_id") if respond_to?(:log)
					Rails.cache.read('DropboxSession:uid')
				end
			end

			def copy_to_local_file(style, destination_path)
			  local_file = File.open(destination_path, "wb")
			  local_file.write(dropbox_client.get_file("/Public#{path(style)}"))
			  local_file.close
			end

			def dropbox_client
				unless Rails.cache.exist?('DropboxSession')
					require 'yaml'
					if @dropbox_client.blank?
						log("loading session from yaml") if respond_to?(:log)
						if File.exists?("#{Rails.root}/config/dropboxsession.yml")
							credentials = YAML::load(File.read("#{Rails.root}/config/dropboxsession.yml"))

							session = DropboxSession.new(credentials[0], credentials[1])
							session.set_access_token(credentials[3], credentials[4])
							@dropbox_client = DropboxClient.new(session, credentials.last)
						end
					end
					@dropbox_client
				else
					log("reading Dropbox Session") if respond_to?(:log)
					Rails.cache.read('DropboxSession')
				end
			end
		end
	end
end
