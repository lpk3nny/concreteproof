// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract BeerConsumer is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    // JavaScript код для Chainlink Nodes
    // Мы берем имя первого пива (index 0) из массива элей
    string public source = 
        "const apiResponse = await Functions.makeHttpRequest({"
        "  url: 'https://api.sampleapis.com/beers/ale'"
        "});"
        "if (apiResponse.error) throw Error('API Error');"
        "const beerName = apiResponse.data[0].name;"
    "return Functions.encodeString(beerName);";

    string public lastBeerName;
    bytes32 public lastRequestId;
    bytes public lastResponse;
    bytes public lastError;

    // Данные для Sepolia (актуально на 2024-2026)
    address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
    // uint16 subscriptionId = 6367;

    constructor() FunctionsClient(router) {}

    /**
     * @notice Отправляет запрос к API
     * @param subscriptionId ID твоей подписки с сайта functions.chain.link
     */
    function requestBeerData(uint64 subscriptionId) external returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); 
        
        // gasLimit: 300,000 (хватит для записи строки)
        lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, 300000, donID);
        return lastRequestId;
    }

    function fulfillRequest(
        bytes32 /* requestId */,
        bytes memory response,
        bytes memory err
    ) internal override {
        lastResponse = response;
        lastError = err;
        
        if (response.length > 0) {
            lastBeerName = string(response);
        }
    }
}
