require "erb"
require "json"
require "time"
require "securerandom"

require "dotenv/load"

namespace :db do
  desc "Create DynamoDB"
  task :create => %i[up terraform:workspace:local terraform:apply:auto]

  desc "Stop local DynamoDB"
  task :down do
    sh %{docker compose down}
  end

  desc "Destroy local DynamoDB"
  task :drop do
    sh %{docker compose down --volumes}
  end

  task :init do
    require "aws-sdk-dynamodb"
    require "aws-sdk-s3"

    class Aws::DynamoDB::Table
      def transact_write_items(transact_items:)
        pages = transact_items.each_slice(25)
        pages.each_with_index do |page,i|
          $stderr.write("PUT #{ client.config.endpoint }/#{ name } [#{ i + 1 }/#{ pages.count }]\n")
          client.transact_write_items(transact_items: page)
        end
      end
    end

    @table  = Aws::DynamoDB::Table.new(name: "Brutalismbot")
    @bucket = Aws::S3::Bucket.new(name: "brutalismbot")

    @workspace = %x(terraform workspace show).strip.to_sym
    if @workspace == :local
      host = %x(docker compose port dynamodb 8000).strip
      @table.client.config.endpoint = "http://#{ host }/"
    end
  end

  desc "Scan DynamoDB"
  task :scan => :init do
    sh <<~SH
      aws dynamodb scan \
      --table-name #{ @table.name } \
      --endpoint-url #{ @table.client.config.endpoint }
    SH
  end

  desc "Seed DynamoDB"
  task :seed => :init do
    require "brutalismbot/reddit/post"
    require "brutalismbot/slack/webhook"

    transact_items = Enumerator.new do |enum|
      ninety_days = 90 * 24 * 60 * 60

      # SLACK/WEBHOOK
      prefix = "data/v1/auths/"
      @bucket.objects(prefix: prefix).map do |obj|
        $stderr.write("GET s3://#{ @bucket.name }/#{ obj.key }\n")
        Brutalismbot::Slack::Webhook.parse(obj.get.body.read)
      end.each do |webhook|
        enum.yield({
          GUID:         "SLACK/WEBHOOK/#{ webhook.key }",
          SORT:         "#{ webhook.team_name }/#{ webhook.channel_name }",
          KIND:         "SLACK/WEBHOOK",
          JSON:         webhook.to_json,
          TEAM_ID:      webhook.team_id,
          TEAM_NAME:    webhook.team_name,
          CHANNEL_ID:   webhook.channel_id,
          CHANNEL_NAME: webhook.channel_name,
          WEBHOOK_KEY:  webhook.key,
          WEBHOOK_URL:  webhook.url.to_s,
        })
      end

      # REDDIT/POST
      prefix = Time.now.utc.strftime("data/v1/posts/year=%Y/month=%Y-%m/day=%Y-%m-%d/")
      reddit_posts = @bucket.objects(prefix: prefix).map do |obj|
        $stderr.write("GET s3://#{ @bucket.name }/#{ obj.key }\n")
        Brutalismbot::Reddit::Post.parse(obj.get.body.read)
      end.each do |post|
        enum.yield({
          GUID:        "REDDIT/POST/#{ post.name }",
          SORT:        post.created_utc.iso8601,
          TTL:         (post.created_utc + ninety_days).to_i,
          KIND:        "REDDIT/POST",
          JSON:        post.to_json,
          CREATED_UTC: post.created_utc.iso8601,
          MEDIA_URLS:  post.media_urls.map(&:to_s),
          NAME:        post.name,
          PERMALINK:   post.permalink,
          TITLE:       post.title,
        })
      end

      # REDDIT/POST/STATS
      reddit_posts.max_by(&:created_utc).then do |post|
        enum.yield({
          GUID:        "REDDIT/POST/STATS",
          SORT:        "MAX",
          KIND:        "STATS",
          CREATED_UTC: post.created_utc.iso8601,
        })
      end
    end.map do |item|
      { put: { table_name: @table.name, item: item } }
    end

    @table.transact_write_items(transact_items: transact_items)
  end

  desc "Print DynamoDB spec JSON"
  task :spec do
    # Gather items
    @items = Enumerator.new do |enum|
      # REDDIT/POST
      created_utc = Time.now.utc - 7 * 24 * 60 * 60
      reddit_posts = 3.times.map do |i|
        created_utc += (SecureRandom.rand * 60 * 60 * 24).to_i
        name         = "t3_" << SecureRandom.alphanumeric(6).downcase

        {
          GUID: { S: "REDDIT/POST/#{ name }" },
          SORT: { S: created_utc.iso8601 },
          KIND: { S: "REDDIT/POST" },
          NAME: { S: name }
        }
      end.each do |post|
        enum.yield(post)
      end

      # REDDIT/POST/STATS
      enum.yield({
        GUID: { S: "REDDIT/POST/STATS" },
        SORT: { S: "MAX" },
        KIND: { S: "STATS" },
      })

      # SLACK/{WEBHOOK,POST}
      3.times.map do |i|
        team_id      = "T01" << SecureRandom.alphanumeric(8).upcase
        team_name    = "<slack-team-#{ i + 1 }>"
        channel_id   = "C01" << SecureRandom.alphanumeric(8).upcase
        channel_name = "<slack-channel-#{ i + 1 }>"

        webhook = {
          GUID: { S: "SLACK/WEBHOOK/#{ team_id }/#{ channel_id }" },
          SORT: { S: "#{ team_name }/#{ channel_name }" },
          KIND: { S: "SLACK/WEBHOOK" },
        }

        enum.yield(webhook)

        reddit_posts.each do |post|
          enum.yield({
            **webhook,
            GUID: { S: "SLACK/POST/#{ team_id }/#{ channel_id }/#{ post.dig(:NAME, :S) }" },
            SORT: { S: post.dig(:SORT, :S) },
            KIND: { S: "SLACK/POST" },
            NAME: { S: post.dig(:NAME, :S) },
          })
        end
      end

      # TWITTER/POST
      reddit_posts.each do |post|
        2.times.map do |i|
          enum.yield({
            GUID: { S: "TWITTER/POST/@brutalismbot/#{ post.dig(:NAME, :S) }" },
            SORT: { S: "#{post.dig(:SORT, :S)}/#{ i + 1 }" },
            KIND: { S: "TWITTER/POST" },
            NAME: { S: post.dig(:NAME, :S) },
          })
        end
      end
    end.sort do |a,b|
      a.slice(:KIND, :GUID, :SORT).values.map { |x| x[:S] } <=>
      b.slice(:KIND, :GUID, :SORT).values.map { |x| x[:S] }
    end

    # Convert to JSON
    template = File.read("Brutalismbot.json.erb")
    result   = ERB.new(template).result
    $stdout.write(JSON.pretty_generate(JSON.parse(result)) << "\n")
  end

  desc "Start local DynamoDB"
  task :up do
    sh %{docker compose up --detach dynamodb}
  end
end

namespace :terraform do
  desc "Apply terraform"
  task :apply => :init do
    sh %{terraform apply}
  end

  desc "Show terraform plan"
  task :plan => :init do
    sh %{terraform plan -detailed-exitcode}
  end

  namespace :apply do
    desc "Auto-apply terraform"
    task :auto => :init do
      sh %{terraform apply -auto-approve}
    end
  end

  task :init => ".terraform"
  directory ".terraform" do
    sh %{terraform init}
  end

  namespace :workspace do
    %i[local prod].each do |name|
      desc "Use #{ name } terraform workspace"
      task name => :init do
        sh %{terraform workspace select #{ name }}
      end
    end
  end
end
