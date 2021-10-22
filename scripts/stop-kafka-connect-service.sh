#!/bin/bash

set -e

ps -ef | grep -v grep | grep -w connect-distributed-modified | awk '{print $2}'