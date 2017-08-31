require 'twitter'

published = false

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = "CONSUMER_KEY"
  config.consumer_secret     = "CONSUMER_SECRET"
  config.access_token        = "ACCESS_TOKEN"
  config.access_token_secret = "ACCESS_TOKEN_SECRET"
end

palabra = File.open("dikshonario.txt").first.strip!

unless palabra.nil?
  puts palabra

  tweet = "#{palabra} https://www.papiamentu.info/palabra/#{palabra} #papiamentu"

  puts tweet

  published = true if client.update(tweet)

  if published
    text=''
    File.open("dikshonario.txt","r"){|f|f.gets;text=f.read}
    File.open("dikshonario.txt","w+"){|f| f.write(text)}
  end

else
  puts "The file your are reading is empty"
end
