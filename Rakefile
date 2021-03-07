require "brutalismbot"
require "brutalismbot/aws/s3"

namespace :local do
  namespace :db do
    desc "Seed local DynamoDB"
    task :seed => %i[seed:webhooks seed:posts]

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
    task :clobber do
      sh "docker-compose down --volumes"
    end

    namespace :seed do
      task :init do
        @bot = Brutalismbot::Client.new
        @s3  = Brutalismbot::Aws::S3::Client.new
      end

      task :webhooks => :init do
        @bot.slack.webhooks.put(*@s3.list_slack_webhooks)
      end

      task :posts => :init do
        @bot.reddit.posts.put(*@s3.list_reddit_posts[-10..-5])
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
  desc "Apply terraform"
  task :apply do
    sh "terraform apply"
  end

  desc "Show terraform plan"
  task :plan do
    sh "terraform plan -detailed-exitcode"
  end

  namespace :apply do
    desc "Auto-apply terraform"
    task :auto do
      sh "terraform apply -auto-approve"
    end
  end

  namespace :workspace do
    desc "Use local terraform workspace"
    task :local do
      sh "terraform workspace select local"
    end

    desc "Use prod terraform workspace"
    task :prod do
      sh "terraform workspace select prod"
    end
  end
end
