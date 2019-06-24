class LinebotController < ApplicationController
  require 'line/bot'
  require 'open-uri'
  
  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if event.message['text'] == 'へるぷ' ||
            event.message['text'] == 'ヘルプ' ||
            event.message['text'].downcase == 'help'
              helpMessage(event)
          elsif event.message['text'] == '都市一覧'
            cityList(event)
          else
            data = event.message['text'].split("の")
            if data.size > 1
              day = data[0]
              cityName = data[1]
            else
              day = ""
              cityName = data[0]
            end
            cityId = getCityId(cityName)
            if cityId == 'error'
              message = {
                type: 'text',
                text: '別の都市を指定してみてください。'
              }
            else
              weather = getWeather(cityId, day)
              if weather == 'error'
                message = {
                  type: 'text',
                  text: "天気が取得できませんでした。
送信したメッセージを見直してください。"
                }
              else
                message = {
                  type: 'text',
                  text: weather
                }
              end
            end
            client.reply_message(event['replyToken'], message)
          end
        end
      end
    }

    head :ok
  end

  def getCityId(cityName)
    ids = CityId.where('city = ?', cityName)
    if ids.size > 0
      return ids[0].city_id
    else
      return 'error'
    end

  end

  def getWeather(cityId, day)
    url = "#{ENV['BASE_URL']}?city=#{cityId}"
    begin
      res = open(url)
      weatherList = JSON.parse(res.read)
    rescue => exception
      return 'error'
    end
    if day == ""
      weather = weatherList['description']['text']
    else
      case day
      when '今日', 'きょう'
        i = 0
      when '明日', 'あす', 'あした', 'みょうにち'
        i = 1
      when '明後日', 'あさって', 'みょうごにち'
        i = 2
      else
        return 'error'
      end
      date = weatherList['forecasts'][i]['date'].split('-')
      dateObject = Date.new(date[0].to_i, date[1].to_i, date[2].to_i)
      weather = "#{weatherList['forecasts'][i]['dateLabel']}（#{dateObject.strftime("%Y年 %m月 %d日")}）の#{weatherList['location']['city']}周辺の天気は、#{weatherList['forecasts'][i]['telop']}です。"
      if !weatherList['forecasts'][i]['temperature']['min'].nil?
        weather += "
最低気温は#{weatherList['forecasts'][i]['temperature']['min']['celsius']}℃"
      end
      if weatherList['forecasts'][i]['temperature']['max'].nil?
        weather += "です。"
      else
        if !weatherList['forecasts'][i]['temperature']['min'].nil?
          weather += "で、"
        end
        weather += "
最高気温は#{weatherList['forecasts'][i]['temperature']['max']['celsius']}℃です。"
      end
    end
    return weather
  end

  def helpMessage(event)
    message = {
      type: 'text',
      text: "使い方

一覧から都市を選び、メッセージを送信してください。
都市名のみを送信した場合、天気の概況を返します。
「今日or明日or明後日」の「都市名」を送信した場合、
指定した日の天気予報を返してくれます。
例：明後日のさいたま

なお、このメッセージがもう一度見たい場合は
「ヘルプ」もしくは「help」と、
都市一覧を見たい場合は
「都市一覧」と
送信してください。"
    }
    client.reply_message(event['replyToken'], message)
  end
  
  def cityList(event)
    message = {
      type: 'text',
      text: "都市一覧1
  
稚内,　旭川,　留萌,　網走,　北見,　紋別,　根室,　釧路,　帯広,　室蘭,　浦河,　札幌,　岩見沢,　倶知安,　函館,　江差,　青森,　むつ,　八戸,　盛岡,　宮古,　大船渡,　仙台,　白石,　秋田,　横手,　山形,　米沢,　酒田,　新庄,　福島,　小名浜,　若松,　水戸,　土浦,　宇都宮,　大田原,　前橋,　みなかみ,　さいたま,　熊谷,　秩父,　千葉,　銚子,　館山,　東京,　大島,　八丈島,　父島,　横浜,　小田原"
    }
    client.reply_message(event['replyToken'], message)
    message = {
      type: 'text',
      text: "都市一覧2
  
新潟,　長岡,　高田,　相川,　富山,　伏木,　金沢,　輪島,　福井,　敦賀,　甲府,　河口湖,　長野,　松本,　飯田,　岐阜,　高山,　静岡,　網代,　三島,　浜松,　名古屋,　豊橋,　津,　尾鷲,　大津,　彦根,　京都,　舞鶴,　大阪,　神戸,　豊岡,　奈良,　風屋,　和歌山,　潮岬,　鳥取,　米子,　松江,　浜田,　西郷,　岡山,　津山,　広島,　庄原,　下関,　山口,　柳井,　萩,　徳島,　日和佐,　高松,　松山,　新居浜,　宇和島,　高知,　室戸岬,　清水,　福岡,　八幡,　飯塚,　久留米,　佐賀,　伊万里,　長崎,　佐世保,　厳原,　福江,　熊本,　阿蘇乙姫,　牛深,　人吉,　大分,　中津,　日田,　佐伯,　宮崎,　延岡,　都城,　高千穂,　鹿児島,　鹿屋,　種子島,　名瀬,　那覇,　名護,　久米島,　南大東,　宮古島,　石垣島,　与那国島"
    }
    client.push_message(event['source']['userId'], message)
  end
end
