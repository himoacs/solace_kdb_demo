# solace_kdb_demo

This repo consists different q scripts that show you how you kdb+ and Solace's PubSub+ work together.

## gen_stats.q
This script consumes raw market data prices which are being published to a PubSub+ queue. 
It then takes that raw data, generates stats, and publishes them back to PubSub+ via dynamic topics (one per sym).
Goal is to show how you can easily consume data from PubSub+, analyze it in real-time in kdb+ and then distribute it
to other applications via PubSub+.
