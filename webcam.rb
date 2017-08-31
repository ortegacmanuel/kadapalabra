require 'twitter'

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = "CONSUMER_KEY"
  config.consumer_secret     = "CONSUMER_SECRET"
  config.access_token        = "ACCESS_TOKEN"
  config.access_token_secret = "ACCESS_TOKEN_SECRET"
end

webcam = "http://190.112.225.27/mjpg/video.mjpg"

cmd="ffmpeg -y -i #{webcam} -vframes 1 -vf fps=fps=1 -f image2 webcam_snapshot.jpg"

system(cmd ) #+ ' 2>/dev/null')

client.update_with_media("#RightNowinCuracao Bibu for di #Kòrsou - Live from #Curaçao", File.new("webcam_snapshot.jpg"))
