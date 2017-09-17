require 'rubygems'
require 'mogli'
require 'RMagick'
require 'httparty'
require 'addressable/uri'
require 'json'

access_token = ''
page_id = ''
published = false
dikshonario_file = File.join(File.dirname(__FILE__), 'dikshonario.txt')

class Palabra
  attr_reader :lexeme
  @@papiamentu_api = 'http://sifma.dijkhofflearning.com'
  @@abclink_api = 'http://abclink.info'

  def initialize(lexeme)
    @lexeme = lexeme
    set_data
    @variants = variants
  end

  def post
    post_data = {}
    post_data[:message] = "#{@lexeme} https://www.papiamentu.info/palabra/#{@lexeme} \n"
    post_data[:name]    = @lexeme
    post_data[:caption] = @lexeme
    post_data[:description] = @lexeme
    post_data[:object_attachment] = @facebook_image
    post_data[:message] += "Informashon tokante e palabra: #{@buki_di_oro} \n"
    post_data[:message] += 'Aprobá: ' << (@aproba ? 'Si' : 'No') << " \n"
    post_data[:message] += 'Standarisá: ' << (@standarisa ? 'Si' : 'No') << " \n"
    post_data[:message] += "Variantenan ortográfiko: #{@variants} \n" if @variants != ''
    post_data[:message] += '#papiamentu'
    post_data
  end

  def set_data
    # https://www.papiamentu.info/palabra/televishon
    url = "#{@@papiamentu_api}/word/#{@lexeme}"
    data = HTTParty.get(Addressable::URI.parse(url).normalize.to_s)
    @buki_di_oro = data[0]['buki_di_oro_text']
    @aproba = data[0]['buki_di_oro'] == 1
    @standarisa = data[0]['attested'] == 1
  end

  def variants
    variants = ''
    url = "#{@@abclink_api}/palabra/#{@lexeme}"
    response = HTTParty.get(Addressable::URI.parse(url).normalize.to_s)
    data = JSON.parse(response.body)
    arr = []
    data.each_with_index { |v, i| arr.include?(v['lexeme']) ? data.delete_at(i) : arr << v['lexeme'] }

    return variants if data.count <= 1
    data.each do |variante|
      variants += "#{variante['orthographic_type']}: #{variante['lexeme']} "
    end

    variants
  end

  def publish_image(client)
    canvas = Magick::Image.new(1200, 628) { self.background_color = '#002b7f' }
    text = Magick::Draw.new
    text.font_family = 'lavi'
    text.pointsize = 140
    text.gravity = Magick::CenterGravity

    text.annotate(canvas, 0, 0, 2, 2, @lexeme) do
      self.fill = 'white'
      self.font_weight = Magick::BoldWeight
    end
    image_file = File.join(File.dirname(__FILE__), "#{@lexeme}.png")
    canvas.write(image_file)

    image = client.post('me/photos', nil, source: File.open(image_file))
    @facebook_image = image['id']
  end
end

client = Mogli::Client.new(access_token)
user = Mogli::User.find('me', client)

page = user.accounts.select do |account|
  account.id.to_s == page_id
end.first

page = Mogli::Page.new(access_token: page.access_token)
page_client = page.client_for_page

first_line = File.open(dikshonario_file).first
raise ArgumentError, 'The file your are reading is empty' if first_line.nil?
first_line.strip!

palabra = Palabra.new(first_line)
palabra.publish_image(page_client)
puts palabra.lexeme
puts palabra.post

published = true if page_client.post('feed', nil, palabra.post)

if published
  text = ''
  File.open(dikshonario_file, 'r') { |f| f.gets; text = f.read }
  File.open(dikshonario_file, 'w+') { |f| f.write(text) }
end
