require "dotenv/load"

require "brutalismbot"
require "brutalismbot/aws/s3"

namespace :local do
  namespace :db do
    desc "Seed local DynamoDB"
    task :seed => %i[seed:reddit seed:slack seed:twitter]

    desc "Create local DynamoDB"
    task :create => %i[up terraform:workspace:local terraform:apply:auto]

    desc "Start local DynamoDB"
    task :up do
      sh "docker-compose up --detach dynamodb"
    end

    desc "Stop local DynamoDB"
    task :down do
      sh "docker-compose down"
    end

    desc "Destroy local DynamoDB"
    task :drop do
      sh "docker-compose down --volumes"
    end

    namespace :seed do
      task :init do
        @bot = Brutalismbot::Client.new
        @s3  = Brutalismbot::Aws::S3::Client.new
      end

      task :slack => %i[slack:webhooks]
      namespace :slack do
        task :webhooks => :init do
          @bot.slack.webhooks.put(*@s3.list_slack_webhooks)
        end
      end

      task :twitter => %i[twitter:apps]
      namespace :twitter do
        task :apps => :init do
          # TODO
        end
      end

      task :reddit => %i[reddit:posts]
      namespace :reddit do
        task :posts => :init do
          @bot.reddit.posts.put(*@s3.list_reddit_posts[-10..-5])
        end
      end
    end
  end
end

namespace :prod do
  namespace :db do
    desc "Create prod DynamoDB"
    task :create => %i[terraform:workspace:prod terraform:apply]
  end
end

namespace :terraform do
  task :init => ".terraform"
  directory ".terraform" do
    sh "terraform init"
  end

  desc "Apply terraform"
  task :apply => :init do
    sh "terraform apply"
  end

  desc "Show terraform plan"
  task :plan => :init do
    sh "terraform plan -detailed-exitcode"
  end

  namespace :apply do
    desc "Auto-apply terraform"
    task :auto => :init do
      sh "terraform apply -auto-approve"
    end
  end

  namespace :workspace do
    desc "Use local terraform workspace"
    task :local => :init do
      sh "terraform workspace select local"
    end

    desc "Use prod terraform workspace"
    task :prod => :init do
      sh "terraform workspace select prod"
    end
  end
end
