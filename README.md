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

## Configuration

You should configure SMTP server information in the `.env.provision`.

```
$ git clone https://github.com/ailispaw/mastodon-barge
$ cd mastodon-barge
$ <your editor> .env.provision
```

```
# E-mail configuration
# Note: Mailgun and SparkPost (https://sparkpo.st/smtp) each have good free tiers
SMTP_SERVER=smtp.mailgun.org
SMTP_PORT=587
SMTP_LOGIN=
SMTP_PASSWORD=
SMTP_FROM_ADDRESS=notifications@example.com
#SMTP_DELIVERY_METHOD=smtp # delivery method can also be sendmail
#SMTP_AUTH_METHOD=plain
#SMTP_OPENSSL_VERIFY_MODE=peer
#SMTP_ENABLE_STARTTLS_AUTO=true
```

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

Cf.) https://github.com/tootsuite/mastodon#running-with-docker-and-docker-compose

## Sign up for the instance
```
http://localhost:3000/
```

## Login to the instance

You will receive a confirmation email to activate your account and click a link in the email.
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
