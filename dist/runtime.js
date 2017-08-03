require('mori');
ws=ws||{};
ws.core=ws.core||{};
ws.core['str']=(function(){ return Array.prototype.slice.call(arguments); });
console.log(ws.core.str(1,2,3));
