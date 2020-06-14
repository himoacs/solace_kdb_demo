// Author: Himanshu Gupta
// This q script is responsible for listening to a Solace topic and capturing all the raw records in real-time.

// Load sol_init.q which has all the PubSub+ configurations
\l common/sol_init.q

// Queue that we would like to subscribe to
topic:`$"EQ/marketData/v1/>";

// Create a global table for capturing L1 quotes and trades
prices:flip (`date`time`sym`exchange`currency`askPrice`askSize`bidPrice`bidSize`tradePrice`tradeSize)!(`date$();`time$();`symbol$();`symbol$();`symbol$();`float$();`float$();`float$();`float$();`float$();`float$());

-1"### Subscribing to topic : ",string topic;

// Define callback function which will be triggered when a new message is received
subUpdate:{[dest;payload;dict]

 // Convert binary payload
 a:"c"$payload;

 // Load JSON to kdb table
 b:.j.k "[",a,"]";

 // Update types of some of the columns
 b:update date:"D"$date, time:"T"$time, symbol:`$symbol, exchange:`$exchange, currency:`$currency from b;
 b:select date,time,sym:symbol,exchange,currency,askPrice,askSize,bidPrice,bidSize,tradePrice,tradeSize from b;

 // Insert into our global prices table
 `prices insert b;
 }

// Assign callback function
.solace.setTopicMsgCallback`subUpdate;
.solace.subscribeTopic[topic;1b];