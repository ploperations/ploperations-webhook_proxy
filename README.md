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
- [Limitations](#limitations)
- [Development](#development)

## Description

This module manages the parts of an Nginx config needed to proxy webhooks, such as those from GitHub, to an internal server that is not directly accessible on the internet.

## Setup

The very basic steps needed for a user to get the module up and running. This can include setup steps, if necessary, or it can be an example of the most basic use of the module.

## Usage

Include usage examples for common use cases in the **Usage** section. Show your users how to use your module to solve problems, and be sure to include code examples. Include three to five examples of the most important or common tasks a user can accomplish with your module. Show users how to accomplish more complex tasks that involve different types, classes, and functions working in tandem.

This module is documented via
`pdk bundle exec puppet strings generate --format markdown`.
Please see [REFERENCE.md](REFERENCE.md) for more info.

## Changelog

[CHANGELOG.md](CHANGELOG.md) is generated prior to each release via
`pdk bundle exec rake changelog`. This proecss relies on labels that are applied
to each pull request.

## Limitations

In the Limitations section, list any incompatibilities, known issues, or other warnings.

## Development

In the Development section, tell other users the ground rules for contributing to your project and how they should submit their work.
