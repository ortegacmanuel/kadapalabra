require "rubygems"
require "mogli"
require 'RMagick'
require 'httparty'
require "addressable/uri"
require 'json'

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

  def data_foi_banko(palabra)
    url = "http://sifma.dijkhofflearning.com/word/#{palabra}"
    response = HTTParty.get(Addressable::URI.parse(url).normalize.to_s)
    #JSON.parse(response)
    #puts response
  end

  def data_foi_bankortografiko(palabra)
    url = "http://abclink.info/palabra/#{palabra}"
    response = HTTParty.get(Addressable::URI.parse(url).normalize.to_s)
    #JSON.parse(response)
  end

  canvas.write(name + ".png")

  return client.post("me/photos", nil, {:source => File.open(name + ".png")})

end

access_token = 'ACCESS_TOKEN'
page_id = 'PAGE_ID'
published = false

client = Mogli::Client.new(access_token)
user = Mogli::User.find("me",client)

page = user.accounts.select do |account|
  account.id.to_s == page_id
end.first

page = Mogli::Page.new(:access_token => page.access_token)
page_client = page.client_for_page

first_line = File.open("dikshonario.txt").first.strip

unless first_line.nil?
  puts first_line
  post_data = {}
  post_data[:message] = first_line + ' https://www.papiamentu.info/palabra/' + first_line + " \n"
  post_data[:name]    = first_line
  post_data[:caption] = first_line
  post_data[:description] = first_line

  # Imagen
  image = create_upload_image(page_client, first_line)
  post_data[:object_attachment] = image["id"]

  # Informashon for di Banko di Palabra
  data = data_foi_banko(first_line)

  post_data[:message] += 'Informashon tokante e palabra: ' + data[0]["buki_di_oro_text"] + " \n"

  if data[0]["buki_di_oro"] == 1
    aproba_text = "Si"
  else
    aproba_text = "No"
  end

  if data[0]["attested"] == 1
    standarisa_text = "Si"
  else
    standarisa_text = "No"
  end

  post_data[:message] += 'Aprobá: '  + aproba_text + " \n"
  post_data[:message] += 'Standarisá: ' + standarisa_text + "\n"

  variantenan = data_foi_bankortografiko(first_line)

  unless variantenan.empty?
    text = ''
    variantenan.each do |variante|
      text += "#{variante["orthographic_type"]}: #{variante["lexeme"]} "
    end
    post_data[:message] += 'Variantenan ortográfiko: '  + text + " \n"
  end

  post_data[:message] += '#papiamentu'

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
