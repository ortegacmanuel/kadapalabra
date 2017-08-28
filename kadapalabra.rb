require "rubygems"
require "mogli"

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
  post_data[:message] = first_line
  post_data[:name]    = first_line
  post_data[:link]    = 'https://www.papiamentu.info/palabra/' + first_line
  post_data[:caption] = first_line
  post_data[:description] = first_line

  published = true if page_client.post("feed", nil, post_data)

  if published
    text=''
    File.open("dikshonario.txt","r"){|f|f.gets;text=f.read}
    File.open("dikshonario.txt","w+"){|f| f.write(text)}
  end

else
  puts "The file your are reading is empty"
end
