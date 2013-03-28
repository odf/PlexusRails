namespace :ssl do
  desc "Create a self-signed SSL certificate to use for local testing"
  task :setup, roles: :app do
    if generate_self_signed_ssl_cert
      template "ssl_cert_info.erb", "/tmp/ssl.txt"
      run "openssl req -new -nodes -keyout /tmp/ssl.key -out /tmp/ssl.csr" +
        " </tmp/ssl.txt"
      run "openssl x509 -req -days 365 -in /tmp/ssl.csr -signkey /tmp/ssl.key" +
        " -out /tmp/ssl.crt"
      run "mkdir -p #{ssl_path}"
      run "mv -n /tmp/ssl.crt #{ssl_path}/#{application}.crt"
      run "chmod 0400 #{ssl_path}/#{application}.crt"
      run "mv -n /tmp/ssl.key #{ssl_path}/#{application}.key"
      run "chmod 0400 #{ssl_path}/#{application}.key"
      run "rm -f /tmp/ssl.txt /tmp/ssl.csr /tmp/ssl.crt /tmp/ssl.key"
    end
  end
  after "deploy:setup", "ssl:setup"
end
