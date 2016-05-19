#!/usr/bin/env ruby

require "thor"
require "pubnub"

# After some experimentation, 12 forks seems to be optimal. Much more runs up the load on the dyno and
# just slows the entire thing down.

class Loki < Thor
  desc "start CHANNEL", "Start an assault against CHANNEL"

  method_option :workers, type: :numeric, default: 12, desc: "Number of workers"
  method_option :length, type: :numeric, :default => 10000, desc: "Length of assult"
  method_option :publish, type: :string, default: '', desc: "PubNub Publish Key"
  method_option :subscribe, type: :string, default: '', desc: "PubNub Subscribe Key"

  def start(args)
    channel = "#{args}-0"
    workers = options[:workers]
    callback = lambda { |envelope| } # Do nothing callback to meet PUBNUB requirements for joining a channel

    sample_text = [
      'Brunch skateboard gastropub Wes Anderson 8-bit keffiyeh, narwhal bitters ',
      'Thundercats pork belly distillery, before they sold out small batch cred XOXO scenester keytar banh mi.',
      'Sustainable lo-fi XOXO chia Carles put a bird on it, bitters semiotics skateboard 90\'s cold-pressed. Bitters Echo Park vinyl hashtag fashion axe cardigan, yr irony Cosby sweater banh mi Wes Anderson master cleanse.',
      'Viral kale chips Helvetica blog. Meh VHS normcore umami yr taxidermy, whatever street art Austin Pitchfork. Wolf Schlitz health goth High Life, Helvetica semiotics DIY pickled hashtag.',
      'Four loko literally listicle post-ironic, biodiesel food truck wolf mumblecore distillery you probably haven\'t heard of them cornhole leggings narwhal deep v.',
      'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro. De carne lumbering animata corpora quaeritis.',
      'Summus brains sit​​, morbo vel maleficia? De apocalypsi gorger omero undead survivor dictum mauris.',
      'Hi mindless mortuis soulless creaturas, imo evil stalking monstra adventus resi dentevil vultus comedat cerebella viventium.',
      'Qui animated corpse, cricket bat max brucks terribilem incessu zomby. The voodoo sacerdos flesh eater, suscitat mortuos comedere carnem virus.',
      'Zonbi tattered for solum oculi eorum defunctis go lum cerebro. Nescio brains an Undead zombies. Sicut malus putrid voodoo horror. Nigh tofth eliv ingdead.',
      'Cum horribilem walking dead resurgere de crazed sepulcris creaturis, zombie sicut de grave feeding iride et serpens.',
      'Now that we know who you are, I know who I am. I\'m not a mistake! It all makes sense!',
      'In a comic, you know how you can tell who the arch-villain\'s going to be? He\'s the exact opposite of the hero. And most times they\'re friends, like you and me!',
      'I should\'ve known way back when... You know why, David? Because of the kids. They called me Mr Glass.'
    ]
    sample_max_range = sample_text.count - 1

    user_images = [
      'http://lorempixel.com/200/200/sports/',
    ]
    user_image_max_range = user_images.count - 1

    if options[:length] == 0
      length = Float::INFINITY
    else
      length = options[:length]
    end

    puts "Workers: #{workers}"
    puts "Length: #{length}"

    puts "Starting a Loki assault..."
    pubnub_logger = Logger.new(STDOUT)

    workers.times do
      user_id = (1..1000).to_a.sample
      pubnub = Pubnub.new(
        publish_key: options[:publish],
        subscribe_key: options[:subscribe],
        #logger: pubnub_logger,
        error_callback: lambda { |msg| puts "Error: #{msg.inspect}" },
        uuid: "user-#{user_id}",
        heartbeat: 3
      )

      pubnub.subscribe(channel: ["#{args}-general", channel]) do |envelope|
        puts "\n\n\nSubscribed to #{envelope.channel}"
      end
      user_image = user_images[(0..user_image_max_range).to_a.sample]

      fork do
        1.upto(length) do
          msg = {
            event: 'chat:message',
            body: sample_text[(0..sample_max_range).to_a.sample],
            channelName: channel,
            quote: nil,
            user: {
              id: user_id,
              name: "User #{user_id}",
              is_admin: false,
              is_broadcaster: false,
              is_self: true,
              region: "CA",
              avatar_large: user_image,
              avatar_medium: user_image
            },
            accessible_product_ids: [276,277],
            time: "2014-06-16T18:11:14.537Z",
            vault: nil
          }

          pubnub.publish(:message => msg, :channel => channel, :http_sync => true)
          puts "Publishing message as USER #{user_id}"

          sleep 1
        end
      end
    end

    #this is just to keep the process from crashing and getting restarted
    sleep
  end

end

Loki.start
