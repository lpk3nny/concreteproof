// Запрос к API
const apiResponse = await Functions.makeHttpRequest({
  url: `https://api.sampleapis.com/beers/ale`
});

if (apiResponse.error) {
  throw Error('Request failed');
}

const data = apiResponse.data;
// Берем название первого пива (например, "Hopleaf Pale Ale")
const beerName = data[0].name;

// Возвращаем результат в виде Buffer (обязательно для Chainlink Functions)
return Functions.encodeString(beerName);
