const url = 'https://api.sampleapis.com/beers/ale'; // В Solidity это массив строк
const res = await Functions.makeHttpRequest({ url });
if (res.error) throw Error('API Error');

const stringData = JSON.stringify(res.data);
const msgUint8 = new TextEncoder().encode(stringData);

// Хешируем (Web Crypto API в Deno)
const hashBuffer = await crypto.subtle.digest("SHA-256", msgUint8);

// Возвращаем напрямую Uint8Array. 
// Нода Chainlink сама поймет, что это нужно передать как `bytes` в Solidity.
return new Uint8Array(hashBuffer);
