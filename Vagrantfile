# A dummy plugin for Barge to set hostname and network correctly at the very first `vagrant up`
module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") { Cap::ChangeHostName }
      guest_capability("linux", "configure_networks") { Cap::ConfigureNetworks }
    end
  end
end

Vagrant.configure(2) do |config|
  config.vm.define "mastodon-barge"

  config.vm.box = "ailispaw/barge"

  config.vm.synced_folder ".", "/vagrant", id: "vagrant"

  config.vm.network :forwarded_port, guest: 3000, host: 3000
  config.vm.network :forwarded_port, guest: 4000, host: 4000
  config.vm.network :forwarded_port, guest: 1080, host: 1080

  config.vm.provision "init", type: "shell" do |sh|
    sh.inline = <<-EOT
      set -e

      wget -q -O /opt/bin/docker-compose \
        https://github.com/docker/compose/releases/download/1.22.0/docker-compose-Linux-x86_64
      chmod +x /opt/bin/docker-compose

      /etc/init.d/docker restart v18.06.1-ce
    EOT
  end

  config.vm.provision "build", type: "shell" do |sh|
    sh.inline = <<-EOT
      set -e

      mkdir -p /opt/mastodon
      cd /opt/mastodon
      cp /vagrant/.env.production .
      cp /vagrant/docker-compose.yml .
      cp /vagrant/Dockerfile .
      cp -R /vagrant/patches .
      docker-compose build
    EOT
  end

  config.vm.provision "config", type: "shell" do |sh|
    sh.inline = <<-EOT
      set -e

      cd /opt/mastodon
      cp /vagrant/.env.production .

      PAPERCLIP_SECRET=$(docker-compose run --rm web rake secret)
      sed -i 's/^PAPERCLIP_SECRET=$/PAPERCLIP_SECRET='${PAPERCLIP_SECRET}'/g' .env.production

      SECRET_KEY_BASE=$(docker-compose run --rm web rake secret)
      sed -i 's/^SECRET_KEY_BASE=$/SECRET_KEY_BASE='${SECRET_KEY_BASE}'/g' .env.production

      OTP_SECRET=$(docker-compose run --rm web rake secret)
      sed -i 's/^OTP_SECRET=$/OTP_SECRET='${OTP_SECRET}'/g' .env.production

      docker-compose run --rm web rake mastodon:webpush:generate_vapid_key >> .env.production
    EOT
  end

  config.vm.provision "setup", type: "shell" do |sh|
    sh.inline = <<-EOT
      set -e

      cd /opt/mastodon

      mkdir -p public/system
      chown -R 1000:1000 public/system

      SKIP_POST_DEPLOYMENT_MIGRATIONS=true docker-compose run --rm web rails db:migrate
    EOT
  end

  config.vm.provision "mastodon", type: "shell" do |sh|
    sh.inline = <<-EOT
      set -e

      cd /opt/mastodon
      docker-compose up -d

      docker-compose run --rm web rails db:migrate
    EOT
  end
end
