# capistranoのバージョンを記載。固定のバージョンを利用し続け、バージョン変更によるトラブルを防止する
lock '3.13.0'

# Capistranoのログの表示に利用する
set :application, 'tenju'

# どのリポジトリからアプリをpullするかを指定する
set :repo_url,  'git@github.com:hikaru08/tenju.git'

# バージョンが変わっても共通で参照するディレクトリを指定
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')

set :rbenv_type, :user
set :rbenv_ruby, '2.5.1' #カリキュラム通りに進めた場合、2.5.1か2.3.1です

set :linked_files, %w{config/master.key}

# どの公開鍵を利用してデプロイするか
set :ssh_options, auth_methods: ['publickey'],
                  keys: ['~/.ssh/tenju.pem'] 

# プロセス番号を記載したファイルの場所
set :unicorn_pid, -> { "#{shared_path}/tmp/pids/unicorn.pid" }

# Unicornの設定ファイルの場所
set :unicorn_config_path, -> { "#{current_path}/config/unicorn.rb" }
set :keep_releases, 5

# デプロイ処理が終わった後、Unicornを再起動するための記述
after 'deploy:publishing', 'deploy:restart', 'deploy:sitemap'
namespace :deploy do
  task :restart do
    invoke 'unicorn:stop'
    invoke 'unicorn:start'
  end
  desc 'upload master.key'
  task :upload do
    on roles(:app) do |host|
      if test "[ ! -d #{shared_path}/config ]"
        execute "mkdir -p #{shared_path}/config"
      end
      upload!('config/master.key', "#{shared_path}/config/master.key")
    end
  end
  before :starting, 'deploy:upload'
  after :finishing, 'deploy:cleanup'
  
  desc 'Generate sitemap'
  task :sitemap do
    on roles(:app) do
      within release_path do
        execute :bundle, :exec, :rake, 'sitemap:create RAILS_ENV=production'
      end
    end
  end
end

