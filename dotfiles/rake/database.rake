namespace :postgresql do
  desc "Init database cluster and start daemon."
  task :start do
    cluster_dir = '/var/tmp/postgresql-cluster'
    bash "rm -rf #{cluster_dir}"
    bash "/usr/lib/postgresql/8.4/bin/initdb -A trust -D #{cluster_dir}"
    bash "/usr/lib/postgresql/8.4/bin/postgres -D #{cluster_dir} -c unix_socket_directory='#{cluster_dir}'"
  end
end

def bash(commandline)
  system "#{ENV['SHELL']} -c '#{commandline}'"
end

namespace :mysql do
  desc "Run mysql."
  task :start do
    mkdir "/var/tmp/mysql", :noop => true
    system "mysql_install_db --datadir=/var/tmp/mysql"
    system "mysqld_safe --skip-syslog --port 93306 --socket=mysqld.sock --pid-file=mysqld.pid --datadir=/var/tmp/mysql"
  end

  desc "Shutdown mysql."
  task :stop do
    system "mysqladmin --password='' -S /var/tmp/mysql/mysqld.sock shutdown"
  end

  desc "Ping mysql."
  task :status do
    system "mysqladmin --password='' -S /var/tmp/mysql/mysqld.sock ping"
  end
end
