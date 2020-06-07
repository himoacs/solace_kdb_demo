// Author: Himanshu Gupta
// This q script is responsible for listening to a Solace PubSub+ queue for market data updates and then, generating
// bar stats every minute. Those stats are then published back to different PubSub+ topics (unique per sym) using this 
// structure: EQ/stats/v1/<sym_name>

// Load sol_init.q which has all the PubSub+ configurations
current_dir: raze system"pwd";
sol_init_file: ssr[current_dir;"generate_stats";"common"],"/sol_init.q"
system "l ",sol_init_file

// Queue that we would like to subscribe to
subQueue:`$"market_data";

// Create a global table for capturing L1 quotes and trades

prices:flip (`date`time`sym`exchange`currency`askPrice`askSize`bidPrice`bidSize`tradePrice`tradeSize)!(`date$();`time$();`symbol$();`symbol$();`symbol$();`float$();`float$();`float$();`float$();`float$();`float$());

-1"### Registering queue message callback";

// Define callback function which will be triggered when a new message is received
subUpdate:{[dest;payload;dict]

 // Convert binary payload
 a:"c"$payload;

 // Load JSON to kdb table
 b:.j.k "[",a,"]";

 // Send ack back to Solace broker
 .solace.sendAck[dest;dict`msgId];

 // Update types of some of the columns
 b:update date:"D"$date, time:"T"$time, symbol:`$symbol, exchange:`$exchange, currency:`$currency from b;
 b:select date,time,sym:symbol,exchange,currency,askPrice,askSize,bidPrice,bidSize,tradePrice,tradeSize from b;

 // Insert into our global prices table
 `prices insert b;
 }

// Assign callback function
.solace.setQueueMsgCallback`subUpdate;

.solace.bindQueue`FLOW_BIND_BLOCKING`FLOW_BIND_ENTITY_ID`FLOW_ACKMODE`FLOW_BIND_NAME!`1`2`2,subQueue;

updateStats:{[rawTable]
 // Generate minutely stats on data from last min
 `prices set rawTable:select from rawTable where time>.z.T-00:01;
 stats:select lowAskSize: min askSize,highAskSize: max askSize,lowBidPrice: min bidPrice,highBidPrice: max bidPrice,lowBidSize: min bidSize,highBidSize: max bidSize,lowTradePrice: min tradePrice,highTradePrice: max tradePrice,lowTradeSize: min tradeSize,highTradeSize: max tradeSize,lowAskPrice: min askPrice,highAskPrice: max askPrice,vwap:tradePrice wavg tradeSize by date, sym, time:1 xbar time.minute from rawTable;
 stats:select from stats where time=max time;

 // Get all the unique syms
 s:exec distinct sym from stats;

 // Generate topic we will publish to for each sym
 t:s!{"EQ/stats/v1/",string(x)} each s;
 show(t);
 // Generate JSON payload from the table for each sym
 a:{[x;y] .j.j select from x where sym=y}[stats;];
 p:s!a each s;

 // Send the payload
 l:{[x;y;z] .solace.sendDirect[`$x[z];y[z]]}[t;p];
 l each s;
 }

// Send generated stats every minute
\t 60000
.z.ts:{updateStats[prices]}
