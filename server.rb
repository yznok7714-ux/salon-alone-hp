require 'socket'
require 'uri'
require 'net/http'
require 'json'

DOCROOT = '/tmp/csks-site'
MIME = {
  '.html' => 'text/html; charset=utf-8',
  '.css'  => 'text/css; charset=utf-8',
  '.js'   => 'application/javascript; charset=utf-8',
  '.png'  => 'image/png',
  '.jpg'  => 'image/jpeg',
  '.svg'  => 'image/svg+xml',
  '.ico'  => 'image/x-icon',
}

# Load .env file if it exists
[File.join(DOCROOT, '.env'), File.expand_path('../../.env', __FILE__)].each do |env_path|
  if File.exist?(env_path)
    File.readlines(env_path).each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      key, value = line.split('=', 2)
      ENV[key.strip] = value.strip.gsub(/\A["']|["']\z/, '') if key && value
    end
    break
  end
end

API_KEY = ENV['ANTHROPIC_API_KEY']

SYSTEM_PROMPT = <<~PROMPT
あなたは美容室「Alone」の公式AIアシスタントです。
お客様からのご質問に、以下の情報に基づいて丁寧にお答えしてください。

═══════════════════════════════════
【サービス名】Alone — プライベートヘアサロン
═══════════════════════════════════

【コンセプト】
「あなたらしさを引き出す場所」をテーマに、完全予約制・マンツーマン対応のプライベートサロンです。
オーナースタイリストが最初のカウンセリングから仕上げまで一貫して担当。
他のお客様を気にせず、リラックスした空間で施術を受けていただけます。
髪質診断に基づくオーダーメイド施術が特長で、一人ひとりに最適なスタイルをご提案します。

【サービス内容】
カット / カラー / パーマ / 次世代オーダーメイドトリートメント / ヘッドスパ
当サロンの看板メニューは「次世代オーダーメイドトリートメント」です。
髪質・ダメージレベルを診断し、最適な成分を組み合わせる完全オーダーメイド処方で、
サロン帰りの仕上がりが長く続きます。

═══════════════════════════════════
【料金（税込）】
═══════════════════════════════════

■ Cut
- カット ¥6,600
- カット + シャンプー・ブロー ¥7,700
- 前髪カット ¥1,100
- キッズカット（小学生以下） ¥4,400

■ Color
- ワンカラー ¥7,700〜
- リタッチカラー ¥6,600〜
- ハイライト ¥5,500〜
- ブリーチ ¥8,800〜

■ Perm
- パーマ ¥8,800〜
- デジタルパーマ ¥13,200〜
- ストレートパーマ ¥13,200〜
- 縮毛矯正 ¥16,500〜

■ Treatment（次世代オーダーメイドトリートメント）
- オーダーメイドトリートメント ¥8,800〜（おすすめ！）
- プレミアムトリートメント ¥5,500〜
- トリートメント ¥3,300〜
- ヘッドスパ ¥4,400〜
- ヘッドスパ + トリートメント ¥6,600〜

■ セットメニュー（お得）
- カット + ワンカラー ¥13,200〜
- カット + パーマ ¥14,300〜
- カット + カラー + トリートメント ¥17,600〜
- カット + 縮毛矯正 ¥22,000〜
- ブリーチ + カラー（ダブルカラー） ¥15,400〜

※料金は髪の長さや状態により変動する場合があります。
※初回ご来店の方は全メニュー10%OFF！

═══════════════════════════════════
【営業時間・連絡先】
═══════════════════════════════════
- 営業時間: 10:00 - 20:00（最終受付 19:00）
- 定休日: 毎週火曜日・第3月曜日
- 住所: 〒150-0001 東京都渋谷区神宮前0-0-0 サンプルビル 2F
- 電話番号: 03-0000-0000
- アクセス: 東京メトロ 表参道駅 A1出口より徒歩5分
- ご予約: ホットペッパービューティー（https://beauty.hotpepper.jp/）からオンライン予約可能
- Instagram: 最新スタイル・サロン情報を発信中
- LINE: お得なクーポン配信中。お気軽にお問い合わせもどうぞ

═══════════════════════════════════
【スタッフ】
═══════════════════════════════════
■ オーナースタイリスト
- 美容師歴15年。都内有名サロンで10年の経験を経て独立
- 得意スタイル: ナチュラル系、透明感カラー、髪質改善トリートメント
- 男女問わず幅広いスタイルに対応
- 「お客様の"なりたい"を超える提案」がモットー
- 毎月最新技術の研修に参加し、トレンドを取り入れています

═══════════════════════════════════
【よくある質問と回答】
═══════════════════════════════════

＜予約・来店＞
Q: 予約なしでも大丈夫ですか？
A: 完全予約制です。ホットペッパービューティーまたはお電話でご予約ください。

Q: 当日予約はできますか？
A: 空きがあれば当日予約も可能です。お電話（03-0000-0000）でお問い合わせください。

Q: 予約の変更はできますか？
A: 前日20時までならホットペッパービューティーまたはお電話で変更可能です。

Q: 遅刻しそうな場合はどうすればいいですか？
A: お電話でご連絡ください。15分以上の遅れは施術内容を調整する場合があります。

Q: キャンセルはいつまでにすればいいですか？
A: 前日20時まで。当日キャンセルは施術料金の50%のキャンセル料が発生する場合があります。

Q: 初めてですが、髪型が決まっていなくても大丈夫ですか？
A: もちろんです！カウンセリングで髪質やライフスタイルに合わせてご提案します。参考画像のお持ち込みも大歓迎です。

＜料金・支払い＞
Q: クレジットカードは使えますか？
A: VISA/Mastercard/JCB/AMEX、電子マネー（交通系IC、iD、QUICPay）、PayPay対応です。

Q: 指名料はかかりますか？
A: オーナー1名のサロンのため指名料は不要です。

Q: 学割はありますか？
A: 学生証ご提示で全メニュー10%OFFです（他割引との併用不可）。

Q: ポイントは貯まりますか？
A: ホットペッパービューティー経由のご予約でPontaポイントが貯まります。

＜施術＞
Q: 施術時間はどのくらいですか？
A: カットのみ約60分、カット+カラー約120分、カット+パーマ約150分が目安です。

Q: トリートメントの所要時間は？
A: 通常トリートメント約30〜45分、オーダーメイドトリートメントは髪質診断込みで約60分です。

Q: カラーはどのくらい持ちますか？
A: 通常1〜2ヶ月程度です。色味や髪質により異なりますので、カウンセリングでご相談ください。

Q: ブリーチは何回必要ですか？
A: 希望の色味と現在の髪色によります。カウンセリングで髪の状態を見てご提案します。

Q: パーマがすぐ取れたら直してもらえますか？
A: 施術後1週間以内にご連絡いただければ無料でお直しいたします。

Q: 白髪染めはできますか？
A: はい。ファッションカラーとの組み合わせで自然な仕上がりも可能です。リタッチカラー ¥6,600〜。

Q: 縮毛矯正とカラーは同日にできますか？
A: 髪の状態によります。ダメージが心配な場合は2回に分けることをおすすめしています。

＜サロン環境＞
Q: 駐車場はありますか？
A: 専用駐車場はございません。近隣にコインパーキングがあります。表参道駅から徒歩5分です。

Q: Wi-Fiはありますか？
A: はい、無料Wi-Fiをご用意しています。パスワードはご来店時にお伝えします。

Q: ドリンクサービスはありますか？
A: コーヒー・紅茶・ハーブティー・お水をご用意しています。

Q: 他のお客様と一緒になりますか？
A: 完全予約制・マンツーマン対応なので、施術中は他のお客様と一緒になりません。

Q: 子連れでも大丈夫ですか？
A: 大歓迎です！プライベート空間なので周りを気にせずお過ごしいただけます。絵本やタブレットもご用意しています。

＜ヘアケア＞
Q: 自宅でのケア方法を教えてもらえますか？
A: はい、施術後に髪質に合ったホームケアのアドバイスをお伝えしています。

Q: サロン専売シャンプーは買えますか？
A: はい、店頭でカウンセリング後にご購入いただけます。オンライン販売は行っていません。

Q: トリートメントの効果はどのくらい持ちますか？
A: 通常のトリートメントで2〜3週間、オーダーメイドトリートメントで1〜1.5ヶ月程度です。

＜その他＞
Q: メンズも対応していますか？
A: はい、男女問わず対応しています。メンズカット ¥6,600です。

Q: 着付けはできますか？
A: 申し訳ございません。着付けは対応しておりません。ヘアセットのみ承ります。

Q: 撮影前のヘアセットはできますか？
A: はい、撮影・イベント用のヘアセットも承ります。ご予約時にご相談ください。

Q: ギフト券はありますか？
A: はい、ご希望の金額でギフト券をご用意できます。プレゼントにもおすすめです。

═══════════════════════════════════
【応答ルール（重要 — 必ず守ること）】
═══════════════════════════════════

＜回答の長さ＞
- 基本は3〜5行で端的にまとめること
- 「メニューを全部教えて」のような全体質問のときだけ一覧を出してOK
- それ以外は聞かれたことだけに答える

＜情報の出し方＞
- 質問された内容にだけ答える。関連情報を全部出さないこと
- 悪い例:「カットの料金は？」→ カラーやパーマの料金も全部出す ← NG
- 良い例:「カットの料金は？」→ カット料金だけ答える ← OK
- 悪い例:「予約方法は？」→ 営業時間・住所・SNSも全部出す ← NG
- 良い例:「予約方法は？」→ 予約方法だけ答える ← OK
- セットメニューや初回特典は、直接関連する質問のときだけ自然に1行添える

＜フォーマット＞
- 改行を使って見やすく整形すること
- 箇条書きには「・」を使い、項目間に改行を入れること
- Markdownの**太字**や##見出しは使わないこと（チャットUIで崩れるため）
- 長い段落は避け、短い文で区切ること

＜口調＞
- 簡潔でフレンドリーな口調
- 絵文字は1回の回答に必ず2個使うこと（例: ✨💇‍♀️😊🌿💆‍♀️✂️🎨💐🌸🪞📱☎️）
- おすすめメニューを聞かれたら「次世代オーダーメイドトリートメント」を推す
- サロンに関係ない質問には丁寧にお断りする
- 対応していないサービス（着付け、ネイル、まつエク、エステ等）を聞かれたら「申し訳ございません、当サロンでは○○は対応しておりません」と明確に伝える
- 医療に関する相談には回答せず、専門医への相談を勧める
PROMPT

def read_request(client)
  # Read request line
  request_line = client.gets
  return nil unless request_line

  method, path, _ = request_line.strip.split(' ')

  # Read headers
  headers = {}
  while (line = client.gets) && line != "\r\n"
    key, value = line.strip.split(': ', 2)
    headers[key.downcase] = value if key && value
  end

  # Read body if Content-Length exists
  body = nil
  if headers['content-length']
    body = client.read(headers['content-length'].to_i)
  end

  { method: method, path: path, headers: headers, body: body }
end

def call_claude_api(messages)
  uri = URI('https://api.anthropic.com/v1/messages')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 30

  request = Net::HTTP::Post.new(uri.path)
  request['Content-Type'] = 'application/json'
  request['x-api-key'] = API_KEY
  request['anthropic-version'] = '2023-06-01'

  request.body = JSON.generate({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 1024,
    system: SYSTEM_PROMPT,
    messages: messages
  })

  response = http.request(request)
  JSON.parse(response.body)
end

def send_response(client, status, content_type, body, extra_headers = {})
  headers = "HTTP/1.1 #{status}\r\nContent-Type: #{content_type}\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n"
  extra_headers.each { |k, v| headers += "#{k}: #{v}\r\n" }
  headers += "\r\n"
  client.print headers
  client.print body
end

def cors_headers
  {
    'Access-Control-Allow-Origin' => '*',
    'Access-Control-Allow-Methods' => 'POST, OPTIONS',
    'Access-Control-Allow-Headers' => 'Content-Type'
  }
end

server = TCPServer.new('0.0.0.0', 8080)
$stderr.puts "Serving #{DOCROOT} on http://localhost:8080"
$stderr.puts API_KEY ? "Claude API key loaded" : "WARNING: ANTHROPIC_API_KEY not set - chat will not work"

loop do
  client = server.accept
  begin
    req = read_request(client)
    next unless req

    path = URI.decode_www_form_component(req[:path])

    # CORS preflight
    if req[:method] == 'OPTIONS' && path == '/api/chat'
      client.print "HTTP/1.1 204 No Content\r\n"
      cors_headers.each { |k, v| client.print "#{k}: #{v}\r\n" }
      client.print "Connection: close\r\n\r\n"
      next
    end

    # Chat API endpoint
    if req[:method] == 'POST' && path == '/api/chat'
      unless API_KEY
        send_response(client, '500 Internal Server Error', 'application/json',
          JSON.generate({ error: 'API key not configured' }), cors_headers)
        next
      end

      begin
        data = JSON.parse(req[:body])
        messages = data['messages'] || []
        result = call_claude_api(messages)

        if result['content']
          reply = result['content'].map { |c| c['text'] }.join('')
          send_response(client, '200 OK', 'application/json',
            JSON.generate({ reply: reply }), cors_headers)
        else
          send_response(client, '500 Internal Server Error', 'application/json',
            JSON.generate({ error: result['error']&.dig('message') || 'Unknown error' }), cors_headers)
        end
      rescue => e
        send_response(client, '500 Internal Server Error', 'application/json',
          JSON.generate({ error: e.message }), cors_headers)
      end
      next
    end

    # Static file serving
    path = '/index.html' if path == '/'
    filepath = File.join(DOCROOT, path)

    if File.exist?(filepath) && !File.directory?(filepath)
      ext = File.extname(filepath)
      mime = MIME[ext] || 'application/octet-stream'
      body = File.binread(filepath)
      send_response(client, '200 OK', mime, body)
    else
      send_response(client, '404 Not Found', 'text/plain', '404 Not Found')
    end
  rescue => e
    $stderr.puts e.message
  ensure
    client.close
  end
end
