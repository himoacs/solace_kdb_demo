# solace_kdb_demo

This repo consists different q scripts that show you how you kdb+ and Solace's PubSub+ work together.

## rdb.q
This script subscribes to a topic directly (without any queues) and loads that data into an in-memory table.

## gen_stats.q
This script consumes raw market data prices and generates minutely stats.

It creates a queue, `market_data`, and binds a topic to that queue. It then takes that raw data, generates stats, and publishes them back to PubSub+ via dynamic topics (one per sym).

Goal is to show how you can easily create a queue, map a topic to it, consume data from PubSub+, analyze it in real-time in kdb+ and then distribute it to other applications via PubSub+.
