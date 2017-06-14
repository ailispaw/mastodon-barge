# Mastodon on Barge with Vagrant

[Mastodon](https://github.com/tootsuite/mastodon) is a free, open-source social network server.
> A decentralized solution to commercial platforms, it avoids the risks of a single company monopolizing your communication. Anyone can run Mastodon and participate in the social network seamlessly.
>
> An alternative implementation of the GNU social project. Based on ActivityStreams, Webfinger, PubsubHubbub and Salmon.

This repo shows how to run a Mastodon instance on [Barge](https://atlas.hashicorp.com/ailispaw/boxes/barge) with [Vagrant](https://www.vagrantup.com/) instantly.

***Note: You may find `LOCAL_HTTPS=false` in `.env.provision` here, therefor, it's just for a local test and don't use this setting in the public.***

## Requirements

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

## Boot up

```
$ vagrant up
```

Or you can do the same procedure one by one as below.

### Create a VM
```
$ vagrant up --no-provision
```

### Build a Mastodon Docker image
```
$ vagrant provision --provision-with build
```

### Configure .env.prodinction with secrets
```
$ vagrant provision --provision-with config
```

### Set up the database and assets
```
$ vagrant provision --provision-with setup
```

### Run a new Mastodon instance
```
$ vagrant provision --provision-with mastodon
```

Cf.) https://github.com/tootsuite/mastodon/tree/v1.2#running-with-docker-and-docker-compose

## Sign up for the instance
```
http://localhost:3000/
```

## Login to the instance

You will receive a confirmation email to activate your account and click a link in the email.

```
http://localhost:1080/
```

Or you can authorize yourself manually from your local console as below, just in case of missing the email or whatever.

```
$ vagrant ssh
[bargee@barge ~]$ cd /opt/mastodon
[bargee@barge mastodon]$ docker-compose run --rm web rails mastodon:confirm_email USER_EMAIL=<your email address>
```

Cf.) https://github.com/tootsuite/documentation/blob/master/Running-Mastodon/Administration-guide.md#confirming-users-manually

## Make an administrator

```
[bargee@barge mastodon]$ docker-compose run --rm web rails mastodon:make_admin USERNAME=<your username>
```

Now you can access to the admin page.
```
http://localhost:3000/admin/settings
```

Cf.) https://github.com/tootsuite/documentation/blob/master/Running-Mastodon/Administration-guide.md#turning-into-an-admin

## Upgrade Mastodon

### Stop the instance

```
$ vagrant ssh
[bargee@barge ~]$ cd /opt/mastodon
[bargee@barge mastodon]$ docker-compose down
```

### Backup

```
[bargee@barge mastodon]$ cd ..
[bargee@barge opt]$ sudo mv mastodon mastodon.bak
```

### Upgrade this repo
```
$ git fetch
$ git checkout <new version>
```

### Build a new Mastodon Docker image
```
$ vagrant provision --provision-with build
```

### Restore configuration files and folders

```
[bargee@barge ~]$ cd /opt/mastodon
[bargee@barge mastodon]$ sudo cp -pR ../mastodon.bak/public .
[bargee@barge mastodon]$ sudo cp /vagrant/.env.production .
```

And then you have to copy the secrets from `/opt/mastodon.bak/.env.production`.

### Upgrade the database and assets
```
$ vagrant provision --provision-with setup
```

### Restart the Mastodon instance
```
$ vagrant provision --provision-with mastodon
```

Cf.) https://github.com/tootsuite/documentation/blob/master/Running-Mastodon/Production-guide.md#things-to-look-out-for-when-upgrading-mastodon
