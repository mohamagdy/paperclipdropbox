require "yaml"
require "dropbox_sdk"

namespace :paperclipdropbox do


	desc "Create DropBox Authorized Session Yaml"
	task :authorize => :environment do

		SESSION_FILE = "#{Rails.root}/config/dropboxsession.yml"

		puts ""
		puts ""
		puts ""

		@dropbox_client = Paperclip::Storage::Dropboxstorage.dropbox_client

		if @dropbox_client.blank?
			if File.exists?("#{Rails.root}/config/paperclipdropbox.yml")
				@options = (YAML.load_file("#{Rails.root}/config/paperclipdropbox.yml")[Rails.env].symbolize_keys)
			end

			@dropbox_key = @options.blank? ? '8ti7qntpcysl91j' : @options[:dropbox_key]
			@dropbox_secret = @options.blank? ? 'i0tshr4cpd1pa4e' : @options[:dropbox_secret]

			@dropbox_client = DropboxSession.new(@dropbox_key, @dropbox_secret)
			@dropbox_client.get_request_token

			puts "Visit #{@dropbox_client.get_authorize_url} to log in to Dropbox. Hit enter when you have done this."

			STDIN.gets

		end

		begin
			@dropbox_client.get_access_token
			puts ""
			puts "Authorized - #{@dropbox_client.authorized?}"
		rescue
			begin
				puts ""
				puts "Visit #{@dropbox_client.get_authorize_url} to log in to Dropbox. Hit enter when you have done this."

				STDIN.gets
				@dropbox_client.authorize
				puts ""
				puts "Authorized - #{@dropbox_client.authorized?}"
			rescue
				puts ""
				puts "Already Authorized - #{@dropbox_client.authorized?}" unless @dropbox_client.blank?
				puts "Failed Authorization. Please try delete /config/dropboxsession.yml and try again." if @dropbox_client.blank?
			end
		end

		puts ""
		puts ""
		unless @dropbox_client.blank?
			File.open(SESSION_FILE, "w") do |f|
				f.puts @dropbox_client.serialize
			end
		end
	end

end