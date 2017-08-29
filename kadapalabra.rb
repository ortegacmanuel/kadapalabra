require "rubygems"
require "mogli"
require 'RMagick'

def create_upload_image(client, name)

  canvas = Magick::Image.new(1200, 628){self.background_color = '#002b7f'}
  text = Magick::Draw.new
  text.font_family = 'lavi'
  text.pointsize = 140
  text.gravity = Magick::CenterGravity

  text.annotate(canvas, 0,0,2,2, name) {
    self.fill = 'white'
    self.font_weight = Magick::BoldWeight
  }

  canvas.write(name + ".png")

  return client.post("me/photos", nil, {:source => File.open(name + ".png")})

end

access_token = 'ACCES_TOKEN'
page_id = 'PAGE_ID'
published = false

client = Mogli::Client.new(access_token)
user = Mogli::User.find("me",client)

page = user.accounts.select do |account|
  account.id.to_s == page_id
end.first

page = Mogli::Page.new(:access_token => page.access_token)
page_client = page.client_for_page

first_line = File.open("dikshonario.txt").first

unless first_line.nil?
  puts first_line
  post_data = {}
  post_data[:message] = first_line + ' https://www.papiamentu.info/palabra/' + first_line + ' #papiamentu'
  post_data[:name]    = first_line
  post_data[:caption] = first_line
  post_data[:description] = first_line

  image = create_upload_image(page_client, first_line)

  post_data[:object_attachment] = image["id"]

  puts post_data

  published = true if page_client.post("feed", nil, post_data)

  if published
    text=''
    File.open("dikshonario.txt","r"){|f|f.gets;text=f.read}
    File.open("dikshonario.txt","w+"){|f| f.write(text)}
  end

else
  puts "The file your are reading is empty"
end
