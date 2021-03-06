require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/r18n'
require 'haml'
require 'open-uri'
require 'sinatra/rdiscount'
require 'sinatra/partial'
require 'sinatra/config_file'
require 'exifr'
require 'aws/s3'

include AWS::S3

#############################################
#              Configuration                #
#############################################

config_file 'config.yml'

set :public_folder, File.dirname(__FILE__) + '/assets/'
enable :partial_underscores

# Email
#set :email_username, ENV['SENDGRID_USERNAME'] || ENV['EMAIL_USERNAME']
#set :email_password, ENV['SENDGRID_PASSWORD'] || ENV['EMAIL_PASSWORD']
#set :email_address, 'me@email.com"
#set :email_service, ENV['EMAIL_SERVICE'] || 'gmail.com'
#set :email_domain, ENV['SENDGRID_DOMAIN'] || 'localhost.localdomain'
#
## AWS
#set :bucket, ENV['S3_BUCKET_NAME'] || nil
#set :s3_key, ENV['AWS_ACCESS_KEY_ID'] || nil
#set :s3_secret, ENV['AWS_SECRET_ACCESS_KEY'] || nil

class MyApp < Sinatra::Base
  register Sinatra::R18n
  register Sinatra::RDiscount
  register Sinatra::Partial
  set :root, File.dirname(__FILE__)
end

###########################################
#                 Routing                 #
###########################################

get '/' do
  @title = t.index.title
  @is_home = true
  @images = Array.new

  if settings.bucket.nil? || settings.s3_key.nil? || settings.s3_secret.nil?
    logger.info("Amazon S3 not properly set up. Bucket: #{settings.bucket}. Key: #{settings.s3_key}. Secret: #{settings.s3_secret}")
  
    @portfolio_dir = "#{File.dirname(__FILE__)}/assets/img/portfolio"

    Dir.entries(@portfolio_dir).each do |file|
      next unless file =~ /.+\.jpg/
      path = "#{@portfolio_dir}/#{file}"
      image = "img/portfolio/#{file}"
      @images.push image
    end
  else
    Base.establish_connection!(
      access_key_id: settings.s3_key,
      secret_access_key: settings.s3_secret
    )

    @portfolio_dir = Bucket.find(settings.bucket)
    
    @portfolio_dir.objects.each do |file|
      image = file.url
      @images.push image
    end
  end

  haml :index, :layout => :layout
end

get '/:page' do
  @title = t[params[:page].to_sym].title
  begin
    haml params[:page].to_sym, :layout => :layout  
  rescue Errno::ENOENT
    raise Sinatra::NotFound
  end
end

post '/contact' do
  require 'pony'
  
  params[:company] ||= ""
  params[:phone] ||= ""

  if params[:message] =~ /(\<a|\[url=)/
    @flash = "You can't include links in your message. Sorry, I get a lot of SPAM. If you're not trying to SPAM me, and links are essential to your message, try emailing directly at: info@jonlaing.com"

    haml :contact, :layout => :layout
  elsif !params[:hp].blank? || params[:company] =~ /google/
    @flash = "Sorry, my SPAM blocker detected this as a SPAM message. If you're legitimately trying to contact me, try emailing me directly: info@jonlaing.com"

    haml :contact, :layout => :layout
  else
    Pony.mail(
      :from => params[:name] + "<" + params[:email] + ">",
      :to => settings.email_address
      :subject => params[:name] + " has contacted you",
      :body => [params[:name],params[:email],params[:company],params[:phone],"",params[:message]].join("\n\n"),
      :port => '587',
      :via => :smtp,
      :via_options => { 
        :address              => 'smtp.'+ settings.email_service, 
        :port                 => '587', 
        :enable_starttls_auto => true, 
        :user_name            => settings.email_username, 
        :password             => settings.email_password, 
        :authentication       => :plain, 
        :domain               => settings.email_domain
      })
    redirect '/success' 
  end
end

#########################################
#             Miscellaneous             #
#########################################

helpers do
  def link_to(text, where = "#", opts = {})
    options = opts.map {|k,v| "#{k}=\"#{v}\"" }.join(" ")
    "<a href=\"#{where}\" #{options}>#{text}</a>"
  end

  def global_setting(name)
  end

  def get_width(img, desired_height)
    if img.height > desired_height
      return img.width*desired_height/img.height
    end
    return img.width
  end

  def get_title(text)
    text.match(/^([#|h1\.]{1,}.+$)|^.+\n=+$/)[0].gsub(/^([#|h1\.])|\n=+$/,'')
  end
  
  def remove_title(text)
    desc = text.gsub(/^([#|h1\.]{1,}.+$)|^.+\n=+$/,'')
    return "No description available" if desc.length < 2
    desc
  end

  def dropdown_from_yaml(yaml)
    out = ""
    yaml.each do |link|
      html = markdown(link).gsub(/\<\/?p\>/,'').gsub(/^(.+)(\>.+\<\/a\>)/, '\1 target="_blank"\2')
      out += "<li>#{html}</li>"
    end
    out
  end

  def is_wide?(width, height)
    width > height
  end

  def social_icons(yaml)
    out = ""
    yaml.each do |link|
      html = markdown(link).gsub(/\<\/?p\>/,'')
      out += "<li>#{html}</li>"
    end
    out
  end
      

end

not_found do
  haml :error404, :layout => :layout
end
