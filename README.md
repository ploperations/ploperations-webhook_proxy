# webhook_proxy

![](https://img.shields.io/puppetforge/pdk-version/ploperations/webhook_proxy.svg?style=popout)
![](https://img.shields.io/puppetforge/v/ploperations/webhook_proxy.svg?style=popout)
![](https://img.shields.io/puppetforge/dt/ploperations/webhook_proxy.svg?style=popout)
[![Build Status](https://travis-ci.org/ploperations/ploperations-webhook_proxy.svg?branch=master)](https://travis-ci.com/ploperations/ploperations-webhook_proxy)

Proxy external webhook endpoints to internal hosts

- [Description](#description)
- [Setup](#setup)
- [Usage](#usage)
- [Changelog](#changelog)
- [Development](#development)

## Description

This module manages the parts of an Nginx config needed to proxy webhooks, such as those from GitHub, to arbitrary internal servers or Jeninks instances that are not directly accessible on the internet.

## Setup

This module assumes you are using ploperations/ssl to manage certificates for Ngnix. Anything related to the base configuration of Nginx will need to be provided in Hiera or via a profile applied to the same server.

## Usage

This module is documented via `pdk bundle exec puppet strings generate --format markdown`. Please see [REFERENCE.md](REFERENCE.md) for more info.

## Changelog

[CHANGELOG.md](CHANGELOG.md) is generated prior to each release via `pdk bundle exec rake changelog`. This process relies on labels that are applied to each pull request.

## Development

Pull requests are welcome!
