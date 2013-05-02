require "yaml"
require "dropbox_sdk"

namespace :paperclipdropbox do


	desc "Create DropBox Authorized Session Yaml"
	task :authorize => :environment do

		SESSION_FILE = "#{Rails.root}/config/dropboxsession.yml"

		puts ""
		puts ""
		puts ""

		@dropboxsession = Paperclip::Storage::Dropboxstorage.dropbox_session

		if @dropboxsession.blank?
			if File.exists?("#{Rails.root}/config/paperclipdropbox.yml")
				@options = (YAML.load_file("#{Rails.root}/config/paperclipdropbox.yml")[Rails.env].symbolize_keys)
			end

			@dropbox_key = @options.blank? ? '8ti7qntpcysl91j' : @options[:dropbox_key]
			@dropbox_secret = @options.blank? ? 'i0tshr4cpd1pa4e' : @options[:dropbox_secret]

			@dropboxsession = DropboxSession.new(@dropbox_key, @dropbox_secret)
			@dropboxsession.get_request_token
			
			puts "Visit #{@dropboxsession.get_authorize_url} to log in to Dropbox. Hit enter when you have done this."

			STDIN.gets

		end

		begin
			@dropboxsession.get_access_token
			puts ""
			puts "Authorized - #{@dropboxsession.authorized?}"
		rescue
			begin
				puts ""
				puts "Visit #{@dropboxsession.get_authorize_url} to log in to Dropbox. Hit enter when you have done this."

				STDIN.gets
				@dropboxsession.authorize
				puts ""
				puts "Authorized - #{@dropboxsession.authorized?}"
			rescue
				puts ""
				puts "Already Authorized - #{@dropboxsession.authorized?}" unless @dropboxsession.blank?
				puts "Failed Authorization. Please try delete /config/dropboxsession.yml and try again." if @dropboxsession.blank?
			end
		end

		puts ""
		puts ""
		unless @dropboxsession.blank?
			File.open(SESSION_FILE, "w") do |f|
				f.puts @dropboxsession.serialize
			end
		end
	end

end